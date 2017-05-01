//
//  Pod.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

public struct PodBuildFile {
    public let skylarkConvertibles: [SkylarkConvertible]
    static let xcconfigTransformer = XCConfigTransformer.defaultTransformer()

    public static func with(podSpec: PodSpec) -> PodBuildFile {
        let libs = PodBuildFile.makeConvertables(fromPodspec: podSpec)
        return PodBuildFile(skylarkConvertibles: libs)
    }
    
    private static func bundleLibraries(withPodSpec spec: PodSpec) -> [ObjcBundleLibrary] {
        return spec.resourceBundles.map { k, v in
            ObjcBundleLibrary(name: "\(spec.name)_\(k)", resources: v)
        }
    }

    public static func makeConvertables(fromPodspec podSpec: PodSpec) -> [SkylarkConvertible] {
        let subspecTargets: [BazelTarget] = podSpec.subspecs.flatMap { spec in
            (bundleLibraries(withPodSpec: podSpec) as [BazelTarget]) +
	            ([ObjcLibrary(rootName: podSpec.name, spec: spec) as BazelTarget])
        }
        
        let rootLib = ObjcLibrary(rootName: podSpec.name,
                                spec: podSpec,
                                extraDeps: subspecTargets.map{ $0.name })
        
        // We don't care about the values here
        // So we just lens to an arbitrary monoid that we can <>
        // Trivial has no information, we just care about whether or not it's nil
        let trivialized: Lens<PodSpecRepresentable, Trivial?> = ReadonlyLens(const(.some(Trivial())))
        
        // Just assume ios for now, we can figure out the proper commands later
        let configs: [SkylarkConvertible] = (
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.ios >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.ios.rawValue,
                                           values: ["cpu": "powerpc1"]) ])) <>
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.osx >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.osx.rawValue,
						                   values: ["cpu": "powerpc2"]) ])) <>
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.tvos >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.tvos.rawValue,
                                           values: ["cpu": "powerpc3"]) ])) <>
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.watchos >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.watchos.rawValue,
                                           values: ["cpu": "powerpc4"]) ]))
        ) ?? []
        
        // TODO(jerrymarino): Remove the runtime-type-cast when your fix lands
        let libs: [SkylarkConvertible] =
            executePruneRedundantCompilationTransform(libs:
                [rootLib] +
                    (subspecTargets.flatMap{ $0 as? ObjcLibrary})
            )
        
        return configs + libs
    }

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

    static func executePruneRedundantCompilationTransform(libs: [ObjcLibrary]) -> [ObjcLibrary] {
        var libByName = [String: ObjcLibrary]()
        libs.forEach { libByName[$0.name] = $0 }

        // Loop through the first degree depedency graph.
        for lib in libs {
            for source in lib.sourceFiles {
                if let deps = lib.deps.basic {
                    for dep in deps {
                        let components = dep.components(separatedBy: ":")
                        guard components.count > 1 else { continue }
                        let depName = components[1]
                        guard let depLib = libByName[depName] else { continue }
                        if fileSetContains(needle: source, haystack: depLib.sourceFiles) {
                            var updatedDep = depLib
                            updatedDep.excludedSource.append(source)
                            libByName[updatedDep.name] = updatedDep
                        }
                    }
                }
                if !lib.deps.multi.isEmpty {
                    // FIXME: Handle the case where we only depend on something for a specific platform
                    continue
                }
            }
        }
        return libs.map { libByName[$0.name]! }
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

typealias SourceFilePatternRep = (headers: [String], sourceFiles: [String])

// Extract Headers and Source Files
// @see getCompiledSource for further docs
func headersAndSources(fromSourceFilePatterns patterns: [String]) -> SourceFilePatternRep {
    var headers = [String]()
    var sourceFiles = [String]()
    for sourceFilePattern in patterns {
        if sourceFilePattern.contains("[") || sourceFilePattern.contains("}") || sourceFilePattern.contains("?") {
            if let header = pattern(fromPattern: sourceFilePattern, includingFileType: "h") {
                headers.append(header)
            }

            sourceFiles += getCompiledSource(fromPatterns: [sourceFilePattern])
        } else if sourceFilePattern.hasSuffix("m") {
            sourceFiles.append(sourceFilePattern)
        } else if sourceFilePattern.hasSuffix("h") {
            headers.append(sourceFilePattern)
        }
    }
    return (headers, sourceFiles)
}
