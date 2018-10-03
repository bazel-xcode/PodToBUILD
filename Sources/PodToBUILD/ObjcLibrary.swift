//
//  ObjcLibrary.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/19/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
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

// https://docs.bazel.build/versions/master/be/objective-c.html#objc_bundle
public struct ObjcBundle: BazelTarget {
    let name: String
    let bundleImports: AttrSet<[String]>

    var acknowledged: Bool {
        return true
    }

    public func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "objc_bundle",
            arguments: [
                .named(name: "name", value: ObjcLibrary.bazelLabel(fromString: name).toSkylark()),
                .named(name: "bundle_imports",
                       value: GlobNode(include: bundleImports.map{ Set($0) },
                                       exclude: AttrSet.empty).toSkylark()),
                ])
    }

    static func extractBundleName(fromPath path: String) -> String {
        return path.components(separatedBy: "/").map { (s: String) in
            s.hasSuffix(".bundle") ? s : ""
            }.reduce("", +).replacingOccurrences(of: ".bundle", with: "")
    }

}

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_bundle_library
public struct ObjcBundleLibrary: BazelTarget {
    let name: String
    let resources: AttrSet<[String]>

    var acknowledged: Bool {
        return true
    }

    public func toSkylark() -> SkylarkNode {
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
public struct ConfigSetting: BazelTarget {
    let name: String
    let values: [String: String]

    public func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "config_setting",
            arguments: [
                .named(name: "name", value: name.toSkylark()),
                .named(name: "values", value: values.toSkylark())
            ])
    }
}

/// Get a dependency name from a name in accordance with
/// CocoaPods dependency naming ( slashes )
/// Versions are ignored!
/// When a given dependency is locally speced, it should
/// Match the PodName i.e. PINCache/Core
func getDependencyName(fromPodDepName podDepName: String, inRootPodNamed rootName: String, moduleName: String?) -> String  {
    let results = podDepName.components(separatedBy: "/")
    if results.count > 1 && results[0] == rootName {
        // This is a local subspec reference
        let join = results[1 ... results.count - 1].joined(separator: "/")
        return ":\(ObjcLibrary.bazelLabel(fromString: join))"
    } else {
        if results.count > 1 {
            return "//Vendor/\(results[0]):\(ObjcLibrary.bazelLabel(fromString: results[1]))"
        } else {
            // This is a reference to another pod library
            return "//Vendor/\(ObjcLibrary.bazelLabel(fromString: results[0])):\(ObjcLibrary.bazelLabel(fromString: results[0]))"
        }
    }
}

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_framework
public struct ObjcFramework: BazelTarget {
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
    public func toSkylark() -> SkylarkNode {
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
public struct ObjcImport: BazelTarget {
    let name: String // A unique name for this rule.
    let archives: AttrSet<[String]> // The list of .a files provided to Objective-C targets that depend on this target.

    var acknowledged: Bool {
        return true
    }

    public func toSkylark() -> SkylarkNode {
        return SkylarkNode.functionCall(
                name: "objc_import",
                arguments: [
                    .named(name: "name", value: name.toSkylark()),
                    .named(name: "archives", value: archives.toSkylark()),
                ]
        )

    }
}

public enum ObjcLibraryConfigurableKeys : String {
    case copts
    case deps
    case sdkFrameworks = "sdk_frameworks"
}

// ObjcLibrary is an intermediate rep of an objc library
public struct ObjcLibrary: BazelTarget, UserConfigurable, SourceExcludable {
    public let name: String
    public let sourceFiles: GlobNode
    public let headers: GlobNode
    public let headerName: AttrSet<String>
    public let weakSdkFrameworks: AttrSet<[String]>
    public let sdkDylibs: AttrSet<[String]>
    public let bundles: AttrSet<[String]>
    public let resources: GlobNode
    public let publicHeaders: AttrSet<Set<String>>
    public let nonArcSrcs: GlobNode
    
    // only used later in transforms
    public let requiresArc: Either<Bool, [String]>

    // "var" properties are user configurable so we need mutation here
    public var sdkFrameworks: AttrSet<[String]>
    public var copts: AttrSet<[String]>
    public var deps: AttrSet<[String]>

    public let isTopLevelTarget: Bool
    public let externalName: String

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
        resources: GlobNode,
        publicHeaders: AttrSet<Set<String>>,
        nonArcSrcs: GlobNode,
        requiresArc: Either<Bool, [String]>,
        isTopLevelTarget: Bool
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
        self.isTopLevelTarget = isTopLevelTarget
    }

    static func bazelLabel(fromString string: String) -> String {
        return string.replacingOccurrences(of: "/", with: "_")
                     .replacingOccurrences(of: "+", with: "_")
    }

    /// Helper to allocate with a podspec
    /// objc_library is used for either C++ compilation or ObjC/C compilation.
    /// There is no way to have rule specific `cpp` opts in Bazel, so we need
    /// to split C++ and ObjC apart.
    /// TODO: Add bazel-discuss thread on this matter.
    /// isSplitDep indicates if the library is a split language dependency
    init(rootSpec: PodSpec? = nil, spec: PodSpec, extraDeps: [String] = [],
            isSplitDep: Bool = false,
            sourceType: BazelSourceLibType = .objc) {
        let fallbackSpec: ComposedSpec = ComposedSpec.create(fromSpecs: [rootSpec, spec].compactMap { $0 })
        self.isTopLevelTarget = rootSpec == nil && isSplitDep == false
        let allSourceFiles = spec ^* liftToAttr(PodSpec.lens.sourceFiles)

        let includeFileTypes = sourceType == .cpp ? CppLikeFileTypes :
                ObjcLikeFileTypes
        let implFiles = extractFiles(fromPattern: allSourceFiles,
                includingFileTypes: includeFileTypes)
            .map { Set($0) }

        let allExcludes = spec ^* liftToAttr(PodSpec.lens.excludeFiles)
        let implExcludes = extractFiles(fromPattern: allExcludes,
                includingFileTypes: CppLikeFileTypes <> ObjcLikeFileTypes)
            .map { Set($0) }

        // TODO: Invoke intersectPatterns (i.e. don't use the bool)
        // TODO: Handle multiplatform overrides of requiresArc
        self.requiresArc = (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.requiresArc))) ?? .left(true)
        self.publicHeaders = (fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.publicHeaders))).map{ Set($0) }

        // Take the name of the primary spec
        let primarySpec = ComposedSpec.create(fromSpecs: [spec, rootSpec].compactMap { $0 })
        let primarySpecName = primarySpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.name))

        let fallbackModuleName = fallbackSpec ^*
            ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.moduleName))

        let rootName = fallbackModuleName ?? primarySpecName

        // Split deps take the name of the source type.
        let splitSuffix = isSplitDep ? sourceType.getLibNameSuffix() : ""
        let baseName = rootSpec == nil ? rootName : ObjcLibrary.bazelLabel(fromString: "\(spec.moduleName ?? spec.name)")
        self.name = baseName + splitSuffix
        self.externalName = rootSpec?.name ?? spec.name

        let xcconfigTransformer =
            XCConfigTransformer.defaultTransformer(externalName: externalName,
                    sourceType: sourceType)


        let xcconfigFlags =
            xcconfigTransformer.compilerFlags(forXCConfig: (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.podTargetXcconfig)))) +
                xcconfigTransformer.compilerFlags(forXCConfig: (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.userTargetXcconfig)))) +
                xcconfigTransformer.compilerFlags(forXCConfig: (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.xcconfig))))
        
        let moduleName = AttrSet<String>(
            value: fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.moduleName))
        )

        let headerDirectoryName: AttrSet<String?> = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.headerDirectory))

        self.headerName = (moduleName.isEmpty ? nil : moduleName) ??
        (headerDirectoryName.basic == nil ? nil :
         headerDirectoryName.denormalize()) ??  AttrSet<String>(value: rootName)

        self.sourceFiles = GlobNode(
            include: implFiles,
            exclude: implExcludes)

        self.headers = GlobNode(
            include: extractFiles(fromPattern: allSourceFiles,
                includingFileTypes: HeaderFileTypes).map{ Set($0) },
            exclude: extractFiles(fromPattern: allExcludes,
                includingFileTypes: HeaderFileTypes).map{ Set($0) })
        self.nonArcSrcs = GlobNode.empty
        self.sdkFrameworks = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.frameworks))

        self.weakSdkFrameworks = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.weakFrameworks))

        self.sdkDylibs = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.libraries))

        // Lift the deps to multiplatform, then get the names of these deps.
        let mpDeps = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.dependencies))
        let mpPodSpecDeps = mpDeps.map { $0.map { getDependencyName(fromPodDepName: $0, inRootPodNamed: primarySpecName, moduleName: rootName) } }

        let extraDepNames = extraDeps.map { ObjcLibrary.bazelLabel(fromString: ":\($0)") }

        self.deps = AttrSet(basic: extraDepNames) <> mpPodSpecDeps

        self.copts = AttrSet(basic: xcconfigFlags.sorted(by: (<))) <> (fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.compilerFlags)))

        // Select resources that are not prebuilt bundles
        let resourceFiles = ((spec ^* liftToAttr(PodSpec.lens.resources)).map { (strArr: [String]) -> [String] in
            strArr.filter({ (str: String) -> Bool in
                !str.hasSuffix(".bundle")
            })
        }).map(extractResources)
        self.resources = GlobNode(
            include: resourceFiles.map{ Set($0) },
            exclude: AttrSet.empty)

        let prebuiltBundles = spec ^* liftToAttr(PodSpec.lens.resources .. ReadonlyLens {
            $0.filter { s in s.hasSuffix(".bundle") }
              .map(ObjcBundle.extractBundleName)
              .map { k in ":\(spec.moduleName ?? spec.name)_Bundle_\(k)" }
              .map(ObjcLibrary.bazelLabel)})

        self.bundles = prebuiltBundles <> (spec ^* liftToAttr(PodSpec.lens.resourceBundles .. ReadonlyLens { $0.map { k, _ in ":\(spec.moduleName ?? spec.name)_Bundle_\(k)" }.map(ObjcLibrary.bazelLabel) }))
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

    func bazelModuleName() -> String {
        if let headerName = headerName.basic {
            return headerName
        }
        return externalName
    }
    
    public func toSkylark() -> SkylarkNode {
        let options = GetBuildOptions()

        // Modules
        let enableModules = options.enableModules
        //let enableModules = false
        let generateModuleMap = options.generateModuleMap
        let headerVisibility = options.headerVisibility

        let lib = self
        let nameArgument = SkylarkFunctionArgument.named(name: "name", value: .string(lib.name))

        var inlineSkylark = [SkylarkNode]()
        var libArguments = [SkylarkFunctionArgument]()

        libArguments.append(nameArgument)
        
        let enableModulesSkylark = SkylarkFunctionArgument.named(name: "enable_modules",
                                                          value: enableModules ? .int(1) : .int(0))
        libArguments.append(enableModulesSkylark)

        let moduleName = bazelModuleName()

        let depHdrs = deps.map {
            $0.filter { $0.hasPrefix(":") && !$0.contains("Vendored") && !$0.contains("_Bundle") }
                .map { ($0 + "_hdrs").toSkylark() }
        }
       
        let allModuleInternalHeaders = headers.toSkylark() .+. depHdrs.toSkylark()

        let podSupportHeaders = GlobNode(include: AttrSet<Set<String>>(basic: [PodSupportSystemPublicHeaderDir + "**/*"]),
                                                         exclude: AttrSet<Set<String>>.empty).toSkylark()
        
        if lib.isTopLevelTarget {
            var exposedHeaders: SkylarkNode = podSupportHeaders
            // By Default we don't propage the headers anymore
            // come up with a way to expose this
            if headerVisibility == "everything" {
                exposedHeaders = exposedHeaders .+. headers.toSkylark()
            }
            
            inlineSkylark.append(.functionCall(
                name: "filegroup",
                arguments: [
                    .named(name: "name", value: (name + "_hdrs").toSkylark()),
                    .named(name: "srcs", value: exposedHeaders),
                    .named(name: "visibility", value: ["//visibility:public"].toSkylark()),
                    ]
                ))   
            
        } else {
            inlineSkylark.append(.functionCall(
                name: "filegroup",
                arguments: [
                    .named(name: "name", value: (name + "_hdrs").toSkylark()),
                    .named(name: "srcs", value: headers.toSkylark()),
                    .named(name: "visibility", value: ["//visibility:public"].toSkylark()),
                    ]
                ))           
        }

        let headerGlobNode = headers

        let hdrsRuleBasename = lib.isTopLevelTarget ? name : moduleName
        let moduleMapDirectoryName = hdrsRuleBasename + "_module_map"
        let clangModuleName = headerName.basic?.replacingOccurrences(of: "-", with: "_")
        if lib.isTopLevelTarget {
            inlineSkylark.append(.functionCall(
                name: "gen_module_map",
                arguments: [
                    .basic(moduleName.toSkylark()),
                    .basic(moduleMapDirectoryName.toSkylark()),
                    .basic(clangModuleName.toSkylark()),
                    .basic([name + "_hdrs"].toSkylark())
                ]
                ))
             if lib.externalName != lib.name {
                 inlineSkylark.append(makeAlias(name: lib.externalName, actual:
                             lib.name))
             }
        }
        
        if !lib.sourceFiles.include.isEmpty {
            if generateModuleMap {
                // Assume that there is going to be headers if we are compiling a module
                libArguments.append(.named(
                    name: "srcs",
                    value: lib.sourceFiles.toSkylark() .+. allModuleInternalHeaders
                    ))
            } else {
                // Workaround: we should be able to add all of the headers here, but in some cases
                // the file group is empty
                // if the header visibility is everything, then the headers will be in hdrs
                let additionalNonPropagatedHdrs: SkylarkNode = (headers.include.isEmpty || headerVisibility == "everything") ? SkylarkNode.empty : headers.toSkylark()
                libArguments.append(.named(
                    name: "srcs",
                    value: lib.sourceFiles.toSkylark() .+. additionalNonPropagatedHdrs
                    ))
            }
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
                .compactMap { $0.count > 1 ? $0.first : nil }
                .map { [$0, "**", "*.pch"].joined(separator: "/") }

            return nestedComponents
        }

        let pchSourcePaths = (lib.sourceFiles.include <> lib.nonArcSrcs.include).fold(basic: {
            if let basic = $0 {
                return buildPCHList(sources: Array(basic))
            }
            return []
        }, multi: { (arr: [String], multi: MultiPlatform<Set<String>>) -> [String] in
            return arr + buildPCHList(sources: [multi.ios, multi.osx, multi.watchos, multi.tvos].compactMap { $0 }.flatMap { Array($0) })
        })

        let headerDirs = lib.headerName.map { PodSupportSystemPublicHeaderDir + "\($0)/" }
        let headerSearchPaths: Set<String> = Set(headerDirs.fold(basic: { str in Set<String>([str].compactMap { $0 }) },
                                  multi: { (result: Set<String>, multi: MultiPlatform<String>) -> Set<String> in
                                    return result.union([multi.ios, multi.osx, multi.watchos, multi.tvos].compactMap { $0 })
                                }))
        if generateModuleMap {
            libArguments.append(.named(
                name: "hdrs",
                value: [moduleMapDirectoryName + "_module_map_file"].toSkylark()
                    .+.  ([hdrsRuleBasename + "_hdrs"]).toSkylark()
                ))
        } else {
            libArguments.append(.named(
                name: "hdrs",
                value: ([":" + hdrsRuleBasename + "_hdrs"]).toSkylark()
                ))
        }

        libArguments.append(.named(
            name: "pch",
            value:.functionCall(
                // Call internal function to find a PCH.
                // @see workspace.bzl
                name: "pch_with_name_hint",
                arguments: [
                    .basic(.string(lib.externalName)),
                    .basic(Array(Set(pchSourcePaths)).sorted(by: (<)).toSkylark())
                ]
            )
        ))

        // Include the public headers which are symlinked in
        // All includes are bubbled up automatically
        libArguments.append(.named(
            name: "includes",
            value: ([PodSupportSystemPublicHeaderDir] + [ moduleMapDirectoryName ]).toSkylark()
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
                value: lib.deps.sorted(by: (<)).toSkylark()
            ))
        }

        let buildConfigDependenctCOpts =
            SkylarkNode.functionCall(name: "select",
                arguments: [
                    .basic([
                         ":release":
                            ["-DPOD_CONFIGURATION_RELEASE=1", "-DNS_BLOCK_ASSERTIONS=1"],
                         "//conditions:default":
                            ["-DPOD_CONFIGURATION_RELEASE=0"]
                     ].toSkylark()
                     )]
            )

        // Include headders
        let iquotes = headerSearchPaths
            .sorted(by: (<))
            .reduce([String]()) {
            accum, searchPath in
            // Assume that the podspec matches the name of the directory.
            // it is a convention that these are 1 in the same.
            let externalDir = options.podName
            return accum + ["-I" + "Vendor/" + externalDir + "/" + searchPath]
        }

        libArguments.append(.named(
            name: "copts",
            value: (lib.copts.toSkylark() .+. buildConfigDependenctCOpts .+.
                iquotes.toSkylark()) <> ["-fmodule-name=" + moduleName + "_pod_module"].toSkylark()))

        if !lib.resources.isEmpty {
            libArguments.append(.named(name: "resources",
                                       value: lib.resources.toSkylark()))
        }

        if !lib.bundles.isEmpty {
            libArguments.append(.named(name: "bundles",
                                       value: lib.bundles.sorted(by: (<)).toSkylark()))
        }
        libArguments.append(.named(
            name: "visibility",
            value: ["//visibility:public"].toSkylark()
        ))
        return .lines(inlineSkylark + [.functionCall(name: "objc_library", arguments: libArguments)])
    }
}

extension ObjcLibrary {
    public enum lens {
        public static let sourceFiles: Lens<ObjcLibrary, GlobNode> = {
            return Lens<ObjcLibrary, GlobNode>(view: { $0.sourceFiles }, set: { sourceFiles, lib in
                ObjcLibrary(name: lib.name, externalName: lib.externalName,
                        sourceFiles: sourceFiles, headers: lib.headers,
                        headerName: lib.headerName, sdkFrameworks:
                        lib.sdkFrameworks, weakSdkFrameworks:
                        lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps:
                        lib.deps, copts: lib.copts, bundles: lib.bundles,
                        resources: lib.resources, publicHeaders:
                        lib.publicHeaders, nonArcSrcs: lib.nonArcSrcs,
                        requiresArc: lib.requiresArc, isTopLevelTarget:
                        lib.isTopLevelTarget)
                })
        }()

        public static let nonArcSrcs: Lens<ObjcLibrary, GlobNode> = {
            return Lens(view: { $0.nonArcSrcs }, set: { nonArcSrcs, lib  in
                ObjcLibrary(name: lib.name, externalName: lib.externalName,
                        sourceFiles: lib.sourceFiles, headers: lib.headers,
                        headerName: lib.headerName, sdkFrameworks:
                        lib.sdkFrameworks, weakSdkFrameworks:
                        lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps:
                        lib.deps, copts: lib.copts, bundles: lib.bundles,
                        resources: lib.resources, publicHeaders:
                        lib.publicHeaders, nonArcSrcs: nonArcSrcs,
                        requiresArc: lib.requiresArc, isTopLevelTarget:
                        lib.isTopLevelTarget)
                })
        }()

        public static let deps: Lens<ObjcLibrary, AttrSet<[String]>> = {
            return Lens(view: { $0.deps }, set: { deps, lib in
                ObjcLibrary(name: lib.name, externalName: lib.externalName,
                        sourceFiles: lib.sourceFiles, headers: lib.headers,
                        headerName: lib.headerName, sdkFrameworks:
                        lib.sdkFrameworks, weakSdkFrameworks:
                        lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps:
                        deps, copts: lib.copts, bundles: lib.bundles,
                        resources: lib.resources, publicHeaders:
                        lib.publicHeaders, nonArcSrcs: lib.nonArcSrcs,
                        requiresArc: lib.requiresArc, isTopLevelTarget:
                        lib.isTopLevelTarget)
                })
        }()

        public static let requiresArc: Lens<ObjcLibrary, Either<Bool, [String]>> = {
	        return Lens(view: { $0.requiresArc }, set: { requiresArc, lib in
                ObjcLibrary(name: lib.name, externalName: lib.externalName,
                        sourceFiles: lib.sourceFiles, headers: lib.headers,
                        headerName: lib.headerName, sdkFrameworks:
                        lib.sdkFrameworks, weakSdkFrameworks:
                        lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps:
                        lib.deps, copts: lib.copts, bundles: lib.bundles,
                        resources: lib.resources, publicHeaders:
                        lib.publicHeaders, nonArcSrcs: lib.nonArcSrcs,
                        requiresArc: requiresArc, isTopLevelTarget:
                        lib.isTopLevelTarget)
            })
        }()

        /// Not a real property -- digs into the glob node
        public static let excludeFiles: Lens<ObjcLibrary, AttrSet<Set<String>>> = {
           return ObjcLibrary.lens.sourceFiles .. GlobNode.lens.exclude
        }()
    }
}

// FIXME: Clean these up and move to RuleUtils
private func extractResources(patterns: [String]) -> [String] {
    return patterns.flatMap { (p: String) -> [String] in
        pattern(fromPattern: p, includingFileTypes: [])
    }
}

