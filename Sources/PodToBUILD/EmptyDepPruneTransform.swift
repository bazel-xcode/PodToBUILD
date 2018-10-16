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

func hasSourcesOnDisk(globNode: GlobNode) -> Bool {
    // TODO: map over all components of the attrsets here.
    let includes = globNode.include.basic ?? Set()
    let excludes = globNode.exclude.basic ?? Set()

    let includedFiles = includes.reduce(into: Set<String>()) {
        accum, pattern in
        Glob(pattern: pattern).paths.forEach { accum.insert($0) }
    }

    let excludedFiles = excludes.reduce(into: Set<String>()) {
        accum, pattern in
        Glob(pattern: pattern).paths.forEach { accum.insert($0) }
    }

    let computedFiles = includedFiles.subtracting(excludedFiles)
    return computedFiles.count > 0
}
            
// EmptyDepPruneTransform hits the file system to strip out deps without source
// Currently, empty swift_library's cause linker issues.
struct EmptyDepPruneTransform : SkylarkConvertibleTransform {
    public static func transform(convertibles: [SkylarkConvertible], options: BuildOptions, podSpec: PodSpec) ->  [SkylarkConvertible] {
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
                    guard hasSourcesOnDisk(globNode: swiftLib.sourceFiles) else {
                        return nil
                    }
                    return dep
                }
            }
            return prunedDeps
        }
        return convertibles.map {
            convertible in
            guard let lib = convertible as? ObjcLibrary else {
                return convertible
            }
            return lib |> (ObjcLibrary.lens.deps %~~ prune)
        }
    }
}
