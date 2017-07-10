//
//  ObjcLibrary.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/19/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation


/// Pod Support Buildable Dir is a directory which is recognized by the build system.
/// it may contain BUILD files, Skylark Extensions, etc.
public let PodSupportBuidableDir = "pod_support_buildable/"

/// Pod Support Dir is the root directory for supporting Pod files
/// It may *not* contain a BUILD file. When a directory contains a BUILD file
/// it must follow all of Bazel's rules including visibility, which adds too
/// much complexity.
public let PodSupportDir = "pod_support/"

/// Pod Support System Public Header Dir is a directory which contains Public
/// headers for a given target. The convention is __Target__/Header.h, which
/// makes it easy to handle angle includes in clang. In the repository
/// initialization phase, all Public headers are symlinked into this directory.
public let PodSupportSystemPublicHeaderDir = "pod_support/Headers/Public/"

/// Law: Names must be valid bazel names; see the spec
protocol BazelTarget: SkylarkConvertible {
    var name: String { get }
    var acknowledgedDeps: [String]? { get }
    var acknowledged: Bool { get }
}

extension BazelTarget {
    var acknowledgedDeps: [String]? {
        return nil 
    }

    var acknowledged: Bool {
        return false
    }
}

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_bundle_library
struct ObjcBundleLibrary: BazelTarget {
    let name: String
    let resources: AttrSet<[String]>

    var acknowledged: Bool {
        return true
    }

    func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "objc_bundle_library",
            arguments: [
                .named(name: "name", value: ObjcLibrary.bazelLabel(fromString: name).toSkylark()),
                .named(name: "resources",
                       value: GlobNode(include: resources.map{ Set($0) },
                                       exclude: AttrSet.empty).toSkylark()),
        ])
    }
}

// https://bazel.build/versions/master/docs/be/general.html#config_setting
struct ConfigSetting: BazelTarget {
    let name: String
    let values: [String: String]

    func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "config_setting",
            arguments: [
		        .named(name: "name", value: name.toSkylark()),
		        .named(name: "values", value: values.toSkylark())
            ])
    }
}

/// rootName -> names -> fixedNames
func fixDependencyNames(rootName: String, moduleName: String?) -> ([String]) -> [String]  {
    return { $0.map { depName in
            // Build up dependencies. Versions are ignored!
            // When a given dependency is locally speced, it should
            // Match the PodName i.e. PINCache/Core
            let results = depName.components(separatedBy: "/")
            if results.count > 1 && results[0] == rootName {
                // This is a local subspec reference
                let join = results[1 ... results.count - 1].joined(separator: "/")
                return ":\(moduleName ?? rootName)_\(ObjcLibrary.bazelLabel(fromString: join))"
            } else {
                if results.count > 1, let podname = results.first {
                    // This is a reference to an external podspec's subspec
                    return "@\(podname)//:\(ObjcLibrary.bazelLabel(fromString: depName))"
                } else {
                    // This is a reference to another pod library
                    return "@\(ObjcLibrary.bazelLabel(fromString: depName))//:\(ObjcLibrary.bazelLabel(fromString: depName))"
                }
            }
        }
    }
}

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_framework
struct ObjcFramework: BazelTarget {
    let name: String // A unique name for this rule.
    let frameworkImports: AttrSet<[String]> // The list of files under a .framework directory which are provided to Objective-C targets that depend on this target.

    var acknowledged: Bool {
        return true
    }

    // objc_framework(
    //     name = "OCMock",
    //     framework_imports = [
    //         glob(["iOS/OCMock.framework/**"]),
    //     ],
    //     is_dynamic = 1,
    //     visibility = ["visibility:public"]
    // )
    func toSkylark() -> SkylarkNode {
        return SkylarkNode.functionCall(
                name: "objc_framework",
                arguments: [
                    .named(name: "name", value: .string(name)),
                    .named(name: "framework_imports",
                           value: GlobNode(
                                include: frameworkImports.map {
                                    Set($0.map { $0 + "/**" })
                                },
	                           exclude: AttrSet.empty
                            ).toSkylark()),
                     // FIXME: provide an API for this.
                     // Assume that every framework is not dynamic.
                     // Typically CocoaPods supports either dynamic or static,
                     // so for the most part, this should be fine.
                    .named(name: "is_dynamic", value: 0),
                    .named(name: "visibility", value: .list(["//visibility:public"]))
                ]
        )
    }
}

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_import
struct ObjcImport: BazelTarget {
    let name: String // A unique name for this rule.
    let archives: AttrSet<[String]> // The list of .a files provided to Objective-C targets that depend on this target.

    var acknowledged: Bool {
        return true
    }

    func toSkylark() -> SkylarkNode {
        return SkylarkNode.functionCall(
                name: "objc_import",
                arguments: [
                    .named(name: "name", value: name.toSkylark()),
                    .named(name: "archives", value: archives.toSkylark()),
                ]
        )

    }
}

enum ObjcLibraryConfigurableKeys : String {
    case copts
    case deps
    case sdkFrameworks = "sdk_frameworks"
}

// ObjcLibrary is an intermediate rep of an objc library
struct ObjcLibrary: BazelTarget, UserConfigurable, SourceExcludable {
    let name: String
    let externalName: String
    let sourceFiles: GlobNode
    let headers: GlobNode
    let headerName: AttrSet<String>
    let weakSdkFrameworks: AttrSet<[String]>
    let sdkDylibs: AttrSet<[String]>
    let bundles: AttrSet<[String]>
    let resources: AttrSet<[String]>
    let publicHeaders: AttrSet<Set<String>>
    let nonArcSrcs: GlobNode

    // only used later in transforms
    let requiresArc: Either<Bool, [String]>

    // "var" properties are user configurable so we need mutation here
    var sdkFrameworks: AttrSet<[String]>
    var copts: AttrSet<[String]>
    var deps: AttrSet<[String]>
    static let xcconfigTransformer = XCConfigTransformer.defaultTransformer()

    init(name: String,
        externalName: String,
        sourceFiles: GlobNode,
        headers: GlobNode,
        headerName: AttrSet<String>,
        sdkFrameworks: AttrSet<[String]>,
        weakSdkFrameworks: AttrSet<[String]>,
        sdkDylibs: AttrSet<[String]>,
        deps: AttrSet<[String]>,
        copts: AttrSet<[String]>,
        bundles: AttrSet<[String]>,
        resources: AttrSet<[String]>,
        publicHeaders: AttrSet<Set<String>>,
        nonArcSrcs: GlobNode,
        requiresArc: Either<Bool, [String]>
    ) {
        self.name = name
        self.externalName = externalName
        self.headerName = headerName
        self.sourceFiles = sourceFiles
        self.headers = headers
        self.sdkFrameworks = sdkFrameworks
        self.weakSdkFrameworks = weakSdkFrameworks
        self.sdkDylibs = sdkDylibs
        self.deps = deps
        self.copts = copts
        self.bundles = bundles
        self.resources = resources
        self.nonArcSrcs = nonArcSrcs
        self.publicHeaders = publicHeaders
        self.requiresArc = requiresArc
    }

    static func bazelLabel(fromString string: String) -> String {
        return string.replacingOccurrences(of: "/", with: "_")
                     .replacingOccurrences(of: "-", with: "_")
                     .replacingOccurrences(of: "+", with: "_")
    }

    init(rootSpec: PodSpec? = nil, spec: PodSpec, extraDeps: [String] = []) {
        let fallbackSpec: ComposedSpec = ComposedSpec.create(fromSpecs: [rootSpec, spec].flatMap { $0 })

        let allSourceFiles = spec ^* liftToAttr(PodSpec.lens.sourceFiles)
        let implFiles = extract(sources: allSourceFiles).map{ Set($0) }
        let allExcludes = spec ^* liftToAttr(PodSpec.lens.excludeFiles)
        let implExcludes = extract(sources: allExcludes).map{ Set($0) }

        // TODO: Invoke intersectPatterns (i.e. don't use the bool)
        // TODO: Handle multiplatform overrides of requiresArc
        /*let needArcPatterns = (spec ^* liftToAttr(PodSpec.lens.requiresArc)).map{ Set($0) }
        let trueArcPatterns = GlobNode(
            include: intersectPatterns(attrSet: implFiles, attrSet2: needArcPatterns),
            exclude: implExcludes
        )
        let trueNoArcPatterns = GlobNode(
            include: implFiles,
            exclude: needArcPatterns <> implExcludes
        )*/
        self.requiresArc = (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.requiresArc))) ?? .left(true)

        self.publicHeaders = (fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.publicHeaders))).map{ Set($0) }

        let xcconfigFlags =
            ObjcLibrary.xcconfigTransformer.compilerFlags(forXCConfig: (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.podTargetXcconfig)))) +
            ObjcLibrary.xcconfigTransformer.compilerFlags(forXCConfig: (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.userTargetXcconfig)))) +
            ObjcLibrary.xcconfigTransformer.compilerFlags(forXCConfig: (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.xcconfig))))

        // We are not using the fallback spec here since
        let fallbackName = ComposedSpec.create(fromSpecs: [spec, rootSpec].flatMap { $0 }) ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.name))
        let rootName = fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.moduleName)) ?? fallbackName

        self.name = rootSpec == nil ? rootName : ObjcLibrary.bazelLabel(fromString: "\(rootName)_\(spec.moduleName ?? spec.name)")
        self.externalName = rootName

        let moduleName = AttrSet<String>(
            value: fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.moduleName))
        )

        let headerDirectoryName: AttrSet<String?> = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.headerDirectory))

        self.headerName = (moduleName.isEmpty ? nil : moduleName) ??
                            (headerDirectoryName.basic == nil ? nil : headerDirectoryName.denormalize()) ??
                            AttrSet<String>(value: rootName)

        self.sourceFiles = GlobNode(
            include: implFiles,
            exclude: implExcludes)
        self.headers = GlobNode(
            include: extract(headers: allSourceFiles).map{ Set($0) },
            exclude: extract(headers: allExcludes).map{ Set($0) })
        self.nonArcSrcs = GlobNode.empty
        self.sdkFrameworks = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.frameworks))

        self.weakSdkFrameworks = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.weakFrameworks))

        self.sdkDylibs = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.libraries))

        let extraDepsSet = AttrSet(basic: extraDeps.map{ ":\($0)" }.map(ObjcLibrary.bazelLabel))
        self.deps = extraDepsSet <> (spec ^* liftToAttr(PodSpec.lens.dependencies .. ReadonlyLens(fixDependencyNames(rootName: fallbackName, moduleName: rootName))))

        self.copts = AttrSet(basic: xcconfigFlags) <> (fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.compilerFlags)))

        self.resources = spec ^* liftToAttr(PodSpec.lens.resources)

        self.bundles = spec ^* liftToAttr(PodSpec.lens.resourceBundles .. ReadonlyLens { $0.map { k, _ in ":\(spec.moduleName ?? spec.name)_Bundle_\(k)" }.map(ObjcLibrary.bazelLabel) })
    }

    mutating func add(configurableKey: String, value: Any) {
        if let key = ObjcLibraryConfigurableKeys(rawValue: configurableKey) {
            switch key {
            case .copts:
                if let value = value as? String {
                    self.copts = self.copts <> AttrSet(basic: [value])
                }
            case .sdkFrameworks:
                if let value = value as? String {
                    self.sdkFrameworks = self.sdkFrameworks <> AttrSet(basic: [value])
                }
            case .deps:
                if let value = value as? String {
                    self.deps = self.deps <> AttrSet(basic: [value])
                }
            }

        }
    }

    // MARK: Source Excludable

    var excludableSourceFiles: AttrSet<Set<String>> {
        return self ^* (ObjcLibrary.lens.sourceFiles .. GlobNode.lens.include)
    }

    var alreadyExcluded: AttrSet<Set<String>> {
        return self ^* ObjcLibrary.lens.excludeFiles
    }

    mutating func addExcluded(sourceFiles: AttrSet<Set<String>>) {
        self = self |> ObjcLibrary.lens.excludeFiles <>~ sourceFiles
    }

    // MARK: BazelTarget

    var acknowledgedDeps: [String]? {
        let basic = deps.basic ?? [String]()
        let multiios = deps.multi.ios ?? [String]()
        let multiosx = deps.multi.osx ?? [String]()
        let multitvos = deps.multi.tvos ?? [String]()
        
        return Array(Set(basic + multiios + multiosx + multitvos))
    }

    var acknowledged: Bool {
        return true
    }

    // MARK: - Bazel Rendering

    func toSkylark() -> SkylarkNode {
        let lib = self
        let nameArgument = SkylarkFunctionArgument.named(name: "name", value: .string(lib.name))

        var inlineSkylark = [SkylarkNode]()
        var libArguments = [SkylarkFunctionArgument]()

        libArguments.append(nameArgument)
        if !lib.sourceFiles.include.isEmpty {
            libArguments.append(.named(
                name: "srcs",
                value: lib.sourceFiles.toSkylark()
            ))
        }
        if !lib.nonArcSrcs.include.isEmpty {
            libArguments.append(.named(
                name: "non_arc_srcs",
                value: lib.nonArcSrcs.toSkylark()
            ))
        }

        func buildPCHList(sources: [String]) -> [String] {
            let nestedComponents = sources
                .map { URL(fileURLWithPath: $0) }
                .map { $0.deletingPathExtension() }
                .map { $0.appendingPathExtension("pch") }
                .map { $0.relativePath }
                .map { $0.components(separatedBy: "/") }
                .flatMap { $0.count > 1 ? $0.first : nil }
                .map { [$0, "**", "*.pch"].joined(separator: "/") }

            return nestedComponents
        }

        let pchSourcePaths = (lib.sourceFiles.include <> lib.nonArcSrcs.include).fold(basic: {
            if let basic = $0 {
                return buildPCHList(sources: Array(basic))
            }
            return []
        }, multi: { (arr: [String], multi: MultiPlatform<Set<String>>) -> [String] in
            return arr + buildPCHList(sources: [multi.ios, multi.osx, multi.watchos, multi.tvos].flatMap { $0 }.flatMap { Array($0) })
        })

        let headerDirs = lib.headerName.map { PodSupportSystemPublicHeaderDir + "\($0)/" }
        let headerSearchPaths: Set<String> = headerDirs.fold(basic: { str in Set<String>([str].flatMap { $0 }) },
                                  multi: { (result: Set<String>, multi: MultiPlatform<String>) -> Set<String> in
                                    return result.union([multi.ios, multi.osx, multi.watchos, multi.tvos].flatMap { $0 })
                                })

        libArguments.append(.named(
            name: "hdrs",
            value: (headers |>
                GlobNode.lens.include <>~ AttrSet<Set<String>>(basic: [PodSupportSystemPublicHeaderDir + "**/*.h"])
            ).toSkylark()
        ))

        libArguments.append(.named(
            name: "pch",
            value:.functionCall(
                // Call internal function to find a PCH.
                // @see workspace.bzl
                name: "pch_with_name_hint",
                arguments: [
                    .basic(.string(lib.externalName)),
                    .basic(Array(Set(pchSourcePaths)).toSkylark())
                ]
            )
        ))

        // Include the public headers which are symlinked in
        // All includes are bubbled up automatically
        libArguments.append(.named(
            name: "includes",
            value: ([PodSupportSystemPublicHeaderDir] + headerSearchPaths).toSkylark()
        ))

        if !lib.sdkFrameworks.isEmpty {
            libArguments.append(.named(
                name: "sdk_frameworks",
                value: lib.sdkFrameworks.toSkylark()
            ))
        }

        if !lib.weakSdkFrameworks.isEmpty {
            libArguments.append(.named(
                name: "weak_sdk_frameworks",
                value: lib.weakSdkFrameworks.toSkylark()
            ))
        }

        if !lib.sdkDylibs.isEmpty {
            libArguments.append(.named(
                name: "sdk_dylibs",
                value: lib.sdkDylibs.toSkylark()
            ))
        }

        if !lib.deps.isEmpty {
            libArguments.append(.named(
                name: "deps",
                value: lib.deps.toSkylark()
            ))
        }

        let buildConfigDependenctCOpts =
            SkylarkNode.functionCall(name: "select",
                                     arguments: [
                                         .basic(
                                             [
                                                 ":release":
                                                    ["-DPOD_CONFIGURATION_RELEASE=1"],
                                                 "//conditions:default":
                                                    ["-DPOD_CONFIGURATION_RELEASE=0"]
                                             ].toSkylark()
                                             )
                                     ]
            )
        libArguments.append(.named(
            name: "copts",
            value: lib.copts.toSkylark() .+. buildConfigDependenctCOpts))

        if !lib.resources.isEmpty {
            libArguments.append(.named(name: "resources",
                                       value: lib.resources.toSkylark()))
        }

        if !lib.bundles.isEmpty {
            libArguments.append(.named(name: "bundles",
                                       value: lib.bundles.toSkylark()))
        }
        libArguments.append(.named(
            name: "visibility",
            value: ["//visibility:public"].toSkylark()
        ))
        return .lines(inlineSkylark + [.functionCall(name: "objc_library", arguments: libArguments)])
    }
}

extension ObjcLibrary {
    enum lens {
        static let sourceFiles: Lens<ObjcLibrary, GlobNode> = {
            return Lens<ObjcLibrary, GlobNode>(view: { $0.sourceFiles }, set: { sourceFiles, lib in
                ObjcLibrary(name: lib.name, externalName: lib.externalName, sourceFiles: sourceFiles, headers: lib.headers, headerName: lib.headerName, sdkFrameworks: lib.sdkFrameworks, weakSdkFrameworks: lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps: lib.deps, copts: lib.copts, bundles: lib.bundles, resources: lib.resources, publicHeaders: lib.publicHeaders, nonArcSrcs: lib.nonArcSrcs, requiresArc: lib.requiresArc)
            })
        }()

        static let nonArcSrcs: Lens<ObjcLibrary, GlobNode> = {
            return Lens(view: { $0.nonArcSrcs }, set: { nonArcSrcs, lib  in
                ObjcLibrary(name: lib.name, externalName: lib.externalName, sourceFiles: lib.sourceFiles, headers: lib.headers, headerName: lib.headerName, sdkFrameworks: lib.sdkFrameworks, weakSdkFrameworks: lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps: lib.deps, copts: lib.copts, bundles: lib.bundles, resources: lib.resources, publicHeaders: lib.publicHeaders, nonArcSrcs: nonArcSrcs, requiresArc: lib.requiresArc)
            })
        }()

        static let deps: Lens<ObjcLibrary, AttrSet<[String]>> = {
            return Lens(view: { $0.deps }, set: { deps, lib in
                ObjcLibrary(name: lib.name, externalName: lib.externalName, sourceFiles: lib.sourceFiles, headers: lib.headers, headerName: lib.headerName, sdkFrameworks: lib.sdkFrameworks, weakSdkFrameworks: lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps: deps, copts: lib.copts, bundles: lib.bundles, resources: lib.resources, publicHeaders: lib.publicHeaders, nonArcSrcs: lib.nonArcSrcs, requiresArc: lib.requiresArc)
            })
        }()

        static let requiresArc: Lens<ObjcLibrary, Either<Bool, [String]>> = {
	        return Lens(view: { $0.requiresArc }, set: { requiresArc, lib in
                ObjcLibrary(name: lib.name, externalName: lib.externalName, sourceFiles: lib.sourceFiles, headers: lib.headers, headerName: lib.headerName, sdkFrameworks: lib.sdkFrameworks, weakSdkFrameworks: lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps: lib.deps, copts: lib.copts, bundles: lib.bundles, resources: lib.resources, publicHeaders: lib.publicHeaders, nonArcSrcs: lib.nonArcSrcs, requiresArc: requiresArc)
            })
        }()

        /// Not a real property -- digs into the glob node
        static let excludeFiles: Lens<ObjcLibrary, AttrSet<Set<String>>> = {
           return ObjcLibrary.lens.sourceFiles .. GlobNode.lens.exclude
        }()
    }
}

private func extractSources(patterns: [String]) -> [String] {
    return patterns.flatMap { (p: String) -> [String] in
        let sourceFileTypes = Set(["m", "mm", "c", "cpp"])
        if let _ = (sourceFileTypes.first{ p.hasSuffix(".\($0)") }) {
            return [p]
        } else {
            // This is domain specific to bazel. Bazel's "glob" can't support wild cards so add
            // multiple entries instead of {m, cpp}
            return sourceFileTypes.flatMap{ pattern(fromPattern: p, includingFileType: $0) }
        }
    }
}

private func extractHeaders(patterns: [String]) -> [String] {
    return patterns.flatMap { (p: String) -> [String] in
        if p.hasSuffix("h") {
            return [p]
        } else {
            return pattern(fromPattern: p, includingFileType: "h").map{ [$0] } ?? []
        }
    }
}

func extract(headers: AttrSet<[String]>) -> AttrSet<[String]> {
    return headers.map(extractHeaders)
}
func extract(sources: AttrSet<[String]>) -> AttrSet<[String]> {
    return sources.map(extractSources)
}
