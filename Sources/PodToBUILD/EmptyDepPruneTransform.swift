//
//  EmptyDepPruneTransform.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 10/16/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

extension Dictionary where Key == String, Value == BazelTarget {
    // Do not rewrite names for @
    // the below logic only works for internal deps.
    func get(bazelName: String) -> BazelTarget? {
        if bazelName.contains("//Vendor") {
            return self[bazelName]
        }
        return bazelName.components(separatedBy: ":").last.flatMap { self[$0] }
    }
    mutating func set(bazelName: String, newValue: BazelTarget) {
        if bazelName.contains("//Vendor") {
            self[bazelName] = newValue
        }
        if let key = bazelName.components(separatedBy: ":").last {
            self[key] = newValue
        }
    }
}

// EmptyDepPruneTransform hits the file system to strip out deps without source
// Currently, empty swift_library's cause linker issues.
struct EmptyDepPruneTransform : SkylarkConvertibleTransform {
    public static func transform(convertibles: [BazelTarget], options:
                                 BuildOptions, podSpec: PodSpec) ->
    [BazelTarget] {
        guard !options.alwaysSplitRules else {
            return convertibles
        }
        // Build up targets that can be stripped
        var targetsByName = [String: BazelTarget]()
        convertibles.forEach {
            convertible in
            // warning: downcasting to BazelTarget here won't work
            guard let target = convertible as? SwiftLibrary else {
                return 
            }
            targetsByName[target.name] = target
        }

        func prune(deps: AttrSet<[String]>, lib: ObjcLibrary) -> AttrSet<[String]> {
            let depSet = lib.deps
            let prunedDeps: AttrSet<[String]> = depSet.map {
                (deps: [String]) in
                return deps.compactMap {
                        dep -> String? in
                    guard let swiftLib = targetsByName.get(bazelName: dep) as? SwiftLibrary else {
                        return dep
                    }
                    // All swift libs require sources on disk
                    guard swiftLib.sourceFiles.basic?.hasSourcesOnDisk() ?? false else {
                        return nil
                    }
                    return dep
                }
            }
            return prunedDeps
        }

        return convertibles.compactMap {
            convertible in
            // This returns a new objc library
            if let lib = convertible as? ObjcLibrary {
                let prunedDeps = prune(deps: lib.deps, lib: lib)
                return ObjcLibrary(name: lib.name, externalName: lib.externalName,
                                sourceFiles: lib.sourceFiles, headers: lib.headers,
                                headerName: lib.headerName, includes: lib.includes,
                                sdkFrameworks: lib.sdkFrameworks, weakSdkFrameworks:
                                lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps:
                                prunedDeps, copts: lib.copts, bundles: lib.bundles, resources:
                                lib.resources, publicHeaders: lib.publicHeaders,
                                nonArcSrcs: lib.nonArcSrcs, requiresArc:
                                lib.requiresArc, isTopLevelTarget: lib.isTopLevelTarget)

            }
            if let lib = convertible as? SwiftLibrary {
               guard lib.sourceFiles.basic?.hasSourcesOnDisk() ?? false else {
                    return nil
                }
                return lib
            }
            return convertible
        }
    }
}
