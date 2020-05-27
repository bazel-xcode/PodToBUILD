//
//  RedundantCompiledSourceTransform.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 5/3/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation


// A target that has files that we are concerned with refining
protocol SourceExcludable : BazelTarget {
    func addExcluded(targets: [BazelTarget]) -> BazelTarget

    var deps: AttrSet<[String]> { get }
}


extension Dictionary where Key == String {
    // Do not rewrite names for @
    // the below logic only works for internal deps.
    func get (bazelName: String) -> Value? {
        if bazelName.contains("//Vendor") || bazelName.contains("@") {
            return self[bazelName]
        }
        return bazelName.components(separatedBy: ":").last.flatMap { self[$0] }
    }

    mutating func set(bazelName: String, newValue: Value) {
        if bazelName.contains("//Vendor") || bazelName.contains("@") {
            self[bazelName] = newValue
        }
        if let key = bazelName.components(separatedBy: ":").last {
            self[key] = newValue
        }
    }
}

struct RedundantCompiledSourceTransform : SkylarkConvertibleTransform {
    // In Cocoapods, all internal targets are flatted to a single target
    // i.e. subspecs are used to describe attributes of source file, have this
    // source code compiled into the top level target
    // In Bazel, this notion is reversed.
    //
    // We need to exclude sources to prevent compiling sources that exist in
    // dependencies.
    //
    // Parent:
    // objc_library(
    //   name = "Core",
    //   srcs = glob(
    //     [
    //       "Source/*.m"
    //     ]
    //   ),
    // Child:
    // objc_library(
    //     name = "Arc_exception_safe",
    //     srcs = glob(
    //       [
    //         "Source/PINDiskCache.m"
    //       ]
    //   ),
    //   deps = [
    //     ":Core"
    //   ],
    
    public static func transform(convertibles: [BazelTarget], options: BuildOptions, podSpec: PodSpec) ->  [BazelTarget] {
        // Needed
        func toSourceExcludable(_ input: BazelTarget) -> SourceExcludable? {
            return input as? SourceExcludable
        }

        // Caveats:
        // - doesn't currently propagate transitive Rdeps.
        // TODO: for react native, it seems like it might be required
        var targetByName = [String: BazelTarget]()
        convertibles.forEach { targetByName[$0.name] = $0 }

        var reverseDeps = [String: [BazelTarget]]()
        convertibles.forEach {
            convertible in
            (convertible as? SourceExcludable)?.deps.basic?.forEach {
                dep in
                let name = dep
                let rDepName = convertible.name
                var arr: [BazelTarget] = reverseDeps.get(bazelName: name) ?? []
                if let t = targetByName.get(bazelName: rDepName) {
                    arr.append(t)
                }
                reverseDeps.set(bazelName: name,  newValue: arr)
            }
        }
        let outputConvertibles = convertibles.compactMap {
            convertible -> BazelTarget? in
            let targetReverseDeps = reverseDeps.get(bazelName: convertible.name) ?? []
            let output = toSourceExcludable(convertible)
            return output?.addExcluded(targets: targetReverseDeps) ??  convertible
        }

        // Rewrite the input with the fixed-excludables
        return outputConvertibles
    }

    static func find(needle: String, haystacks: [String]) -> Bool {
        return haystacks.first { glob(pattern: $0, contains: needle) } != nil
    }
}
