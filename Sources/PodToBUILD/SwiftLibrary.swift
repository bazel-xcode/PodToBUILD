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
    public let moduleMap: ModuleMap?
    public let moduleName: String
    public let deps: AttrSet<[String]>
    public let copts: AttrSet<[String]>
    public let swiftcInputs: AttrSet<[String]>

    public let isTopLevelTarget: Bool
    public let externalName: String
    public let data: AttrSet<GlobNode>

    public init(name: String,
                sourceFiles: AttrSet<GlobNode>,
                moduleMap: ModuleMap?,
                moduleName: String,
                deps: AttrSet<[String]>,
                copts: AttrSet<[String]>,
                swiftcInputs: AttrSet<[String]>,
                isTopLevelTarget: Bool,
                externalName: String,
                data: AttrSet<GlobNode>) {
        self.name = name
        self.sourceFiles = sourceFiles
        self.moduleMap = moduleMap
        self.moduleName = moduleName
        self.externalName = externalName

        self.isTopLevelTarget = isTopLevelTarget
        self.deps = deps
        self.copts = copts
        self.swiftcInputs = swiftcInputs

        self.data = data
    }

    public static func hasSwiftSources(spec: PodSpec) -> Bool {
        return SwiftLibrary.getSources(spec: spec).hasSourcesOnDisk()
    }

    /// For swift, we crush the podspec sources into 1 lib
    /// The function returns a union all the the spec's sources
    private static func getSources(spec: PodSpec) -> AttrSet<GlobNode> {
        let allSourceFiles = spec.attr(\.sourceFiles)
        let implFiles = extractFiles(fromPattern: allSourceFiles,
             includingFileTypes: SwiftLikeFileTypes)
            .unpackToMulti()
            .map { Set($0) }

        let allExcludes = spec.attr(\.excludeFiles)
        let implExcludes = extractFiles(fromPattern: allExcludes,
            includingFileTypes: SwiftLikeFileTypes)
            .unpackToMulti()
            .map { Set($0) }

        // Apply excludes to the sources
        let specSources = implFiles.zip(implExcludes).map {
            GlobNode(include: .left($0.first ?? Set()), exclude: .left($0.second ?? Set()))
        }
        let subspecSources: [AttrSet<GlobNode>] = spec.selectedSubspecs()
            .map { getSources(spec: $0) }
        return specSources.zip(AttrSet.empty.sequence(subspecSources))
           .map {
            attrTuple -> GlobNode in
            let first = attrTuple.first ?? .empty
            let second: [GlobNode] = attrTuple.second ?? []
            if first != .empty, second.count > 0 {
                let include = ([first] + second).map { Either<Set<String>, GlobNode>.right($0) }
                return GlobNode(include: include, exclude: [])
            } else if second.count > 0 {
                return GlobNode(include: second.map { Either<Set<String>, GlobNode>.right($0) }, exclude: [])
            } else if first != .empty {
                return first
            } else {
                return .empty
            }
        }
    }

    /// Note: this initializer has assumptions on the way that it's used, and
    /// all subspec sources are collected here.
    /// there is 1 swift_library per podspec
    init(parentSpecs: [PodSpec], spec: PodSpec, extraDeps: [String] = [],
         isSplitDep: Bool = false,
         moduleMap: ModuleMap? = nil) {
        isTopLevelTarget = parentSpecs.isEmpty && isSplitDep == false
        let podName = GetBuildOptions().podName
        let name = computeLibName(
            parentSpecs: parentSpecs,
            spec: spec,
            podName: podName,
            isSplitDep: isSplitDep,
            sourceType: .swift
        )
        self.name = name 

        self.sourceFiles = SwiftLibrary.getSources(spec: spec)

        let externalName = getNamePrefix() + (parentSpecs.first?.name ?? spec.name)
        self.externalName = externalName

        let resourceFiles = (spec.attr(\.resources).map { (strArr: [String]) -> [String] in
            strArr.filter { (str: String) -> Bool in
                !str.hasSuffix(".bundle")
            }
        }).map(extractResources)

        let fallbackSpec = FallbackSpec(specs: [spec] +  parentSpecs)
        let headerDirectoryName: AttrSet<String?> = fallbackSpec.attr(\.headerDirectory)
        let moduleName: AttrSet<String> = fallbackSpec.attr(\.moduleName).map {
            $0 ?? ""
        }

        let headerName = (moduleName.isEmpty ? nil : moduleName) ??
            (headerDirectoryName.basic == nil ? nil :
                headerDirectoryName.denormalize()) ?? AttrSet<String>(value:
                externalName)
        let clangModuleName = headerName.basic?.replacingOccurrences(of: "-", with: "_") ?? ""
        self.moduleName = clangModuleName

        self.data = resourceFiles.map { GlobNode(include: Set($0)) }

        // Extract deps from the entire podspec
        let allDepsArr: [AttrSet<[String]>] = ([spec] + spec.selectedSubspecs())
            .map { $0.attr(\.dependencies) }
        let allDeps = AttrSet.empty.sequence(allDepsArr).map {
            depsArr -> [String] in
            return depsArr.reduce([String]()) { $0 + $1 }
        }
        // `swift_library` depends on the public interface
        self.deps = allDeps.map {
            $0.map {
                getDependencyName(fromPodDepName: $0, podName: podName)
            }.filter {
                $0.hasPrefix("//") || $0.hasPrefix("@")
            }
        }
 
        let swiftFlags = XCConfigTransformer.defaultTransformer(
            externalName: externalName, sourceType: .swift)
            .compilerFlags(for: fallbackSpec)

        let objcFlags = XCConfigTransformer.defaultTransformer(
            externalName: externalName, sourceType: .objc)
            .compilerFlags(for: fallbackSpec)

        let includes = objcFlags.filter { $0.hasPrefix("-I") }

        // Insert the clang import flags
        // This adds -DCOCOAPODS and -DCOCOAPODS=1 to the clang importer ( via
        // -Xcc ) - by doing this, clang sees -DCOCOAPODS=1. I'm not 100% sure
        // why it doesn't pass -DCOCOAPODS=1 to swift, but this is the behavior
        // in Xcode make it identical
        let clangImporterCopts = (includes + ["-DCOCOAPODS=1"])
            .reduce([String]()) { $0 + ["-Xcc", $1] }
        self.copts = AttrSet(basic: [
            "-DCOCOAPODS",
        ] + swiftFlags + clangImporterCopts)

        self.swiftcInputs = AttrSet.empty
        self.moduleMap = moduleMap
    }

    public func toSkylark() -> SkylarkNode {
        var swiftcInputs = self.swiftcInputs
        var copts = self.copts
        let options = GetBuildOptions()
        // Note: we don't expose this module map upwards.
        // Dependent top level objc libraries will expose an extended module map
        let headerMapName = self.name.replacingOccurrences(of: "_swift", with: "")
        if options.generateHeaderMap {
            swiftcInputs = swiftcInputs <> AttrSet(basic: [
                ":" + headerMapName + "_hmap",
            ])
            copts = copts <> AttrSet(basic: [
                "-Xcc",
                "-I$(execpath " + headerMapName + "_hmap)",
            ])
        }

        copts = copts <> AttrSet(basic: [
            "-Xcc",
            "-I.",
        ])
        let deps = self.deps
        if let moduleMap = self.moduleMap {
            copts = copts <> AttrSet(basic: [
                "-Xcc",
                "-D__SWIFTC__",
                "-Xfrontend",
                "-no-clang-module-breadcrumbs",
                "-Xcc",
                "-fmodule-map-file=$(execpath " + moduleMap.name + ")",
                "-import-underlying-module",
            ])
            swiftcInputs = swiftcInputs <> AttrSet(basic: [
                ":" + moduleMap.name,
            ])
            if let umbrellaHeader = moduleMap.umbrellaHeader {
                swiftcInputs = swiftcInputs <> AttrSet(basic: [
                    ":" + umbrellaHeader
                ])
            }
        }

        let depsSkylark = deps.map {
            Set($0).sorted(by: (<))
        }.toSkylark()
        let buildConfigDependenctCOpts: SkylarkNode =
            .functionCall(name: "select",
             arguments: [
                 .basic([
                     ":release": [
                         "-Xcc", "-DPOD_CONFIGURATION_RELEASE=1",
                      ],
                     "//conditions:default": [
                         "-enable-testing",
                         "-DDEBUG",
                         "-Xcc", "-DPOD_CONFIGURATION_DEBUG=1",
                         "-Xcc", "-DDEBUG=1",
                     ],
                 ].toSkylark()
                 ),
             ])

        let coptsSkylark = buildConfigDependenctCOpts .+. copts.toSkylark()
        return .functionCall(
            name: "swift_library",
            arguments: [
                .named(name: "name", value: name.toSkylark()),
                .named(name: "module_name", value: moduleName.toSkylark()),
                .named(name: "srcs", value: sourceFiles.toSkylark()),
                .named(name: "deps", value: depsSkylark),
                .named(name: "data", value: data.toSkylark()),
                .named(name: "copts", value: coptsSkylark),
                .named(name: "swiftc_inputs", value: swiftcInputs.toSkylark()),
                .named(name: "generated_header_name", value: (externalName + "-Swift.h").toSkylark()),
                .named(name: "features", value: ["swift.no_generated_module_map"].toSkylark()),
                .named(name: "visibility", value: ["//visibility:public"].toSkylark()),
            ]
        )
    }
}

private func extractResources(patterns: [String]) -> [String] {
    return patterns.flatMap { (p: String) -> [String] in
        pattern(fromPattern: p, includingFileTypes: [])
    }
}

extension PodSpec {
    func allSubspecs(_ isSubspec: Bool = false) -> [PodSpec] {
        return (isSubspec ? [self] : []) + self.subspecs.reduce([PodSpec]()) {
            return $0 + $1.allSubspecs(true)
        }
    }


    /// Returns selected subspecs
    /// Note: because we reduce sources into a single swift library, it must
    /// consider subspecs that are included, otherwise, it would pull in sources
    /// from the entire podspec.
    /// Currently it uses `Default` subspecs.
    /// Ideally, should be a way to add other sources to this.
    func selectedSubspecs() -> [PodSpec] {
        let defaultSubspecs = Set(self.defaultSubspecs)
        let subspecs = allSubspecs()
        guard !defaultSubspecs.isEmpty else {
            return subspecs
        }
        return subspecs.filter { defaultSubspecs.contains($0.name) }
    }
}
