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
    var excludableSourceFiles: [String] { get }

    mutating func addExcludedSourceFile(sourceFile: String)

    var deps: AttrSet<[String]> { get }
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

    public static func transform(convertibles: [SkylarkConvertible], options: BuildOptions) ->  [SkylarkConvertible] {
        // Needed
        func toSourceExcludable(_ input: SkylarkConvertible) -> SourceExcludable? {
            return input as? SourceExcludable
        }

        var excludableByName = [String: SourceExcludable]()
        convertibles.flatMap(toSourceExcludable).forEach {
            excludableByName[$0.name] = $0
        }

        // Return updated convertibles
        func updated(convertible: SkylarkConvertible) -> SkylarkConvertible {
            guard let excludable = toSourceExcludable(convertible),
                let updated = excludableByName[excludable.name] else {
                    return convertible
            }
            return updated
        }
        
        // Loop through the first degree depedency graph.
        // TODO? Handle the case where we only depend on something for a 
        // specific platform and Nth degree excludes?
        convertibles.flatMap(toSourceExcludable).forEach {
            let excludable = $0
            for source in excludable.excludableSourceFiles {
                excludable.deps.basic.flatMap { $0 }?.forEach {
                    let components = $0.components(separatedBy: ":")
                    guard components.count > 1 else { return }
                    let depName = components[1]
                    guard let depLib = excludableByName[depName] else { return }
                    if fileSetContains(needle: source, haystack: depLib.excludableSourceFiles) {
                        var updatedDep = depLib
                        updatedDep.addExcludedSourceFile(sourceFile: source)
                        excludableByName[updatedDep.name] = updatedDep
                    }
                }
            }
        }
        return convertibles.map(updated)
    }

    static func fileSetContains(needle: String, haystack: [String]) -> Bool {
        for hay in haystack {
            if glob(pattern: hay, contains: needle) {
                return true
            }
        }
        return false
    }
}
