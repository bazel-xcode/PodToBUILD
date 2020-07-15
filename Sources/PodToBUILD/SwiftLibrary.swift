//
//  SwiftLibrary.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 10/16/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

// Represent a swift_library in Bazel
// https://github.com/bazelbuild/rules_swift/blob/master/doc/rules.md#swift_library
// Note: Swift support is currently in progress
// TODO:
// - XCConfig / compiler flags
public struct SwiftLibrary: BazelTarget {
    public let name: String
    public let sourceFiles: AttrSet<GlobNode>
    public let deps: AttrSet<[String]>

    public let isTopLevelTarget: Bool
    public let externalName: String
    public let data: AttrSet<GlobNode>

    public init(name: String,
                sourceFiles: AttrSet<GlobNode>,
                deps: AttrSet<[String]>,
                isTopLevelTarget: Bool,
                externalName: String,
                data: AttrSet<GlobNode>) {
        self.name = name
        self.sourceFiles = sourceFiles
        self.externalName = externalName

        self.isTopLevelTarget = isTopLevelTarget
        self.deps = deps
        self.data = data
    }


    init(parentSpecs: [PodSpec], spec: PodSpec, extraDeps: [String] = [],
            isSplitDep: Bool = false) {
        let fallbackSpec = FallbackSpec(specs: parentSpecs + [spec])
        self.isTopLevelTarget = parentSpecs.isEmpty && isSplitDep == false

        let podName = GetBuildOptions().podName
        self.name = computeLibName(
                parentSpecs: parentSpecs,
                spec: spec,
                podName: podName,
                isSplitDep: isSplitDep,
                sourceType: .swift
        )

        let allSourceFiles = spec.attr(\.sourceFiles)
        let implFiles = extractFiles(fromPattern: allSourceFiles,
                includingFileTypes: SwiftLikeFileTypes)
            .map { Set($0) }


        let allExcludes = spec.attr(\.excludeFiles)
        let implExcludes = extractFiles(fromPattern: allExcludes,
                includingFileTypes: SwiftLikeFileTypes)
            .map { Set($0) }

        self.sourceFiles = implFiles.zip(implExcludes).unpackToMulti().map {
            t -> GlobNode in
            return GlobNode(include: .left(t.first ?? Set()), exclude: .left(t.second ?? Set()))
        }

        self.externalName = parentSpecs.first?.name ?? spec.name

        let resourceFiles = (spec.attr(\.resources).map { (strArr: [String]) -> [String] in
            strArr.filter({ (str: String) -> Bool in
                !str.hasSuffix(".bundle")
            })
        }).map(extractResources)
        self.data = resourceFiles.map{ GlobNode(include: Set($0)) }
        // Lift the deps to multiplatform, then get the names of these deps.
        let mpDeps = fallbackSpec.attr(\.dependencies)
        let mpPodSpecDeps = mpDeps.map { $0.map {
            getDependencyName(fromPodDepName: $0, podName: podName) } }

        let extraDepNames = extraDeps.map { bazelLabel(fromString: ":\($0)") }

        self.deps = AttrSet(basic: extraDepNames) <> mpPodSpecDeps
    }

    public func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "swift_library",
            arguments: [
                .named(name: "name", value: name.toSkylark()),
                .named(name: "srcs", value: sourceFiles.toSkylark()),
                .named(name: "deps", value: deps.sorted(by: (<)).toSkylark()),
                .named(name: "data", value: data.toSkylark())
            ])
    }
}

private func extractResources(patterns: [String]) -> [String] {
    return patterns.flatMap { (p: String) -> [String] in
        pattern(fromPattern: p, includingFileTypes: [])
    }
}

