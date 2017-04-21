//
//  Pod.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

struct PodBuildFile {
    var skylarkConvertibles: [SkylarkConvertible]

    static func with(podSpec: PodSpec) -> PodBuildFile {
        let libs = PodBuildFile.makeConvertables(fromPodspec: podSpec)
        return PodBuildFile(skylarkConvertibles: libs)
    }

    static func makeConvertables(fromPodspec podSpec: PodSpec) -> [SkylarkConvertible] {
        var deps = [String]()
        var objcLibs = [SkylarkConvertible]()

        for subSpec in podSpec.subspecs {
            let subspecName = bazelLabel(fromString: "\(podSpec.name)_\(subSpec.name)")
            let workspaceLabel = ":" + subspecName
            deps.append(workspaceLabel)

            var subspecDeps = [String]()
            for depName in subSpec.dependencies {
                // Build up dependencies. Versions are ignored!
                // When a given dependency is locally speced, it should
                // Match the PodName i.e. PINCache/Core
                let results = depName.components(separatedBy: "/")
                if results.count > 1 && results[0] == podSpec.name {
                    let join = results[1 ... results.count - 1].joined(separator: "/")
                    subspecDeps.append(":\(podSpec.name)_\(bazelLabel(fromString: join))")
                } else {
                    subspecDeps.append("@\(depName)//:\(depName)")
                }
            }
            
            let headersAndSourcesInfo = headersAndSources(fromSourceFilePatterns: subSpec.sourceFiles)
            let lib = ObjcLibrary(name: subspecName,
                                  sourceFiles: headersAndSourcesInfo.sourceFiles,
                                  headers: headersAndSourcesInfo.headers,
                                  sdkFrameworks: subSpec.frameworks,
                                  sdkDylibs: subSpec.libraries,
                                  deps: subspecDeps,
                                  copts: subSpec.compilerFlags,
                                  bundles: subSpec.resourceBundles.map { k, _ in ":\(subSpec.name)-\(k)" },
                                  excludedSource: getCompiledSource(fromPatterns: subSpec.excludeFiles))

            let bundles: [SkylarkConvertible] = subSpec.resourceBundles.map { k, v in
                ObjcBundleLibrary(name: "\(subSpec.name)-\(k)", resources: v)
            }
            objcLibs.append(lib)
            objcLibs.append(contentsOf: bundles)
        }

        let headersAndSourcesInfo = headersAndSources(fromSourceFilePatterns: podSpec.sourceFiles)


        let lib = ObjcLibrary(name: podSpec.name,
                              sourceFiles: headersAndSourcesInfo.sourceFiles,
                              headers: headersAndSourcesInfo.headers,
                              sdkFrameworks: podSpec.frameworks,
                              sdkDylibs: podSpec.libraries,
                              deps: deps,
                              copts: podSpec.compilerFlags,
                              bundles: podSpec.resourceBundles.map { k, _ in ":\(podSpec.name)-\(k)" },
                              excludedSource: getCompiledSource(fromPatterns: podSpec.excludeFiles))

        objcLibs.insert(lib, at: 0)

        let bundles: [SkylarkConvertible] = podSpec.resourceBundles.map { k, v in
            ObjcBundleLibrary(name: "\(podSpec.name)-\(k)", resources: v)
        }

        // Apply Transformations
        return bundles + objcLibs.filter { $0 as? ObjcLibrary == nil } + executePruneRedundantCompilationTransform(libs: objcLibs.flatMap { $0 as? ObjcLibrary })
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
                for dep in lib.deps {
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

// This is domain specific to bazel. Bazel's "glob" can't support wild cards so add
// multiple entries instead of {m, cpp}
// @see GlobUtils for further docs
private func getCompiledSource(fromPatterns patterns: [String]) -> [String] {
    var sourceFiles = [String]()
    for sourceFilePattern in patterns {
        if let impl = pattern(fromPattern: sourceFilePattern, includingFileType: "m") {
            sourceFiles.append(impl)
        }
        if let impl = pattern(fromPattern: sourceFilePattern, includingFileType: "mm") {
            sourceFiles.append(impl)
        }
        if let impl = pattern(fromPattern: sourceFilePattern, includingFileType: "cpp") {
            sourceFiles.append(impl)
        }
        if let impl = pattern(fromPattern: sourceFilePattern, includingFileType: "c") {
            sourceFiles.append(impl)
        }
    }
    return sourceFiles
}

private func bazelLabel(fromString string: String) -> String {
    return string.replacingOccurrences(of: "\\/", with: "_").replacingOccurrences(of: "-", with: "_")
}
