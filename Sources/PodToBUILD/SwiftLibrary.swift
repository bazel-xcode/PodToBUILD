//
//  SwiftLibrary.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 10/16/18.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

// Represent a swift_library in Bazel
// https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-swift.md
// Note: Swift support is currently in progress
// TODO:
// - XCConfig / compiler flags
public struct SwiftLibrary: BazelTarget {
    public let name: String
    public let sourceFiles: GlobNode
    public let deps: AttrSet<[String]>

    public let isTopLevelTarget: Bool
    public let externalName: String
    public let resources: GlobNode

    init(rootSpec: PodSpec? = nil, spec: PodSpec, extraDeps: [String] = [],
            isSplitDep: Bool = false) {
        let fallbackSpec: ComposedSpec = ComposedSpec.create(fromSpecs: [rootSpec, spec].compactMap { $0 })
        self.isTopLevelTarget = rootSpec == nil && isSplitDep == false

        // Take the name of the primary spec
        let primarySpec = ComposedSpec.create(fromSpecs: [spec, rootSpec].compactMap { $0 })
        let primarySpecName = primarySpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.name))

        let fallbackModuleName = fallbackSpec ^*
            ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.moduleName))

        let rootName = fallbackModuleName ?? primarySpecName

        // Split deps take the name of the source type.
        let splitSuffix = isSplitDep ? BazelSourceLibType.swift.getLibNameSuffix() : ""
        let baseName = rootSpec == nil ? rootName : ObjcLibrary.bazelLabel(fromString: "\(spec.moduleName ?? spec.name)")
        self.name = baseName + splitSuffix
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
        self.externalName = rootSpec?.name ?? spec.name

        let resourceFiles = ((spec ^* liftToAttr(PodSpec.lens.resources)).map { (strArr: [String]) -> [String] in
            strArr.filter({ (str: String) -> Bool in
                !str.hasSuffix(".bundle")
            })
        }).map(extractResources)
        self.resources = GlobNode(
            include: resourceFiles.map{ Set($0) },
            exclude: AttrSet.empty)

        // Lift the deps to multiplatform, then get the names of these deps.
        let mpDeps = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.dependencies))
        let mpPodSpecDeps = mpDeps.map { $0.map { getDependencyName(fromPodDepName: $0, inRootPodNamed: primarySpecName, moduleName: rootName) } }

        let extraDepNames = extraDeps.map { ObjcLibrary.bazelLabel(fromString: ":\($0)") }

        self.deps = AttrSet(basic: extraDepNames) <> mpPodSpecDeps
    }

    public func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "swift_library",
            arguments: [
                .named(name: "name", value: name.toSkylark()),
                .named(name: "srcs", value: sourceFiles.toSkylark()),
                .named(name: "deps", value: deps.sorted(by: (<)).toSkylark()),
                .named(name: "resources", value: resources.toSkylark())
            ])
    }
}

private func extractResources(patterns: [String]) -> [String] {
    return patterns.flatMap { (p: String) -> [String] in
        pattern(fromPattern: p, includingFileTypes: [])
    }
}

