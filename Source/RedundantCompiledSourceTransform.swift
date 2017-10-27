//
//  RedundantCompiledSourceTransform.swift
//  PodSpecToBUILD
//
//  Created by jerry on 5/3/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation


// A target that has files that we are concerned with refining
protocol SourceExcludable : BazelTarget {
    var excludableSourceFiles: AttrSet<Set<String>> { get }
    var alreadyExcluded: AttrSet<Set<String>> { get }

    mutating func addExcluded(sourceFiles: AttrSet<Set<String>>)

    var deps: AttrSet<[String]> { get }
}
extension Dictionary where Key == String, Value == SourceExcludable {
    // Do not rewrite names for @
    // the below logic only works for internal deps.
    func get(bazelName: String) -> SourceExcludable? {
        if bazelName.contains("//Vendor") {
            return self[bazelName]
        }
        return bazelName.components(separatedBy: ":").last.flatMap { self[$0] }
	}
    mutating func set(bazelName: String, newValue: SourceExcludable) {
        if bazelName.contains("//Vendor") {
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
    
    // DFS traversal across a set of SourceExcludables
    // At each step we propagate along includes and excludes from some dependency to it's parent
    private static func fixUnspecifiedSourceExcludesInGraphFrom(
        root: SourceExcludable,
        excludableByName: inout [String: SourceExcludable]
    ) {
		root.deps.basic.flatMap { $0 }?.forEach { depName in
            guard var updatedDep: SourceExcludable = excludableByName.get(bazelName: depName) else { return }
            
            updatedDep.addExcluded(sourceFiles: root.excludableSourceFiles <> root.alreadyExcluded)
            excludableByName[updatedDep.name] = updatedDep
            
            fixUnspecifiedSourceExcludesInGraphFrom(
                root: excludableByName[updatedDep.name] ?? updatedDep,
                excludableByName: &excludableByName
            )
        }       
    }

    public static func transform(convertibles: [SkylarkConvertible], options: BuildOptions, podSpec: PodSpec) ->  [SkylarkConvertible] {
        // Needed
        func toSourceExcludable(_ input: SkylarkConvertible) -> SourceExcludable? {
            return input as? SourceExcludable
        }

        // Initialize the dictionary
        var excludableByName = [String: SourceExcludable]()
        convertibles.flatMap(toSourceExcludable).forEach { excludableByName[$0.name] = $0 }

        // DFS through the depedency graph.
        convertibles.flatMap(toSourceExcludable).forEach { excludable in
            fixUnspecifiedSourceExcludesInGraphFrom(
                root: excludable,
                excludableByName: &excludableByName
            )
        }
        
        // Rewrite the input with the fixed-excludables
        return convertibles.map{ toSourceExcludable($0).flatMap{ excludableByName[$0.name] } ?? $0 }
    }

    static func find(needle: String, haystacks: [String]) -> Bool {
        return haystacks.first { glob(pattern: $0, contains: needle) } != nil
    }
}
