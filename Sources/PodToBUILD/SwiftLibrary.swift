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
    public let sourceFiles: GlobNode
    public let deps: AttrSet<[String]>

    public let isTopLevelTarget: Bool
    public let externalName: String
    public let data: GlobNode

    init(parentSpecs: [PodSpec], spec: PodSpec, extraDeps: [String] = [],
            isSplitDep: Bool = false) {
        let fallbackSpec: ComposedSpec = ComposedSpec.create(fromSpecs: parentSpecs + [spec])
        self.isTopLevelTarget = parentSpecs.isEmpty && isSplitDep == false

        let podName = GetBuildOptions().podName
        self.name = computeLibName(
                parentSpecs: parentSpecs,
                spec: spec,
                podName: podName,
                isSplitDep: isSplitDep,
                sourceType: .swift
        )

        let allSourceFiles = spec ^* liftToAttr(PodSpec.lens.sourceFiles)
        let implFiles = extractFiles(fromPattern: allSourceFiles,
                includingFileTypes: SwiftLikeFileTypes)
            .map { Set($0) }


        let allExcludes = spec ^* liftToAttr(PodSpec.lens.excludeFiles)
        let implExcludes = extractFiles(fromPattern: allExcludes,
                includingFileTypes: SwiftLikeFileTypes)
            .map { Set($0) }

        self.sourceFiles = GlobNode(
            include: implFiles,
            exclude: implExcludes)
        self.externalName = parentSpecs.first?.name ?? spec.name

        let resourceFiles = ((spec ^* liftToAttr(PodSpec.lens.resources)).map { (strArr: [String]) -> [String] in
            strArr.filter({ (str: String) -> Bool in
                !str.hasSuffix(".bundle")
            })
        }).map(extractResources)
        self.data = GlobNode(
            include: resourceFiles.map{ Set($0) },
            exclude: AttrSet.empty)

        // Lift the deps to multiplatform, then get the names of these deps.
        let mpDeps = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.dependencies))
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

