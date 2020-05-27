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

// https://github.com/bazelbuild/rules_apple/blob/master/doc/rules-resources.md#apple_bundle_import
public struct AppleBundleImport: BazelTarget {
    public let name: String
    let bundleImports: AttrSet<[String]>

    public var acknowledged: Bool {
        return true
    }

    public func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "apple_bundle_import",
            arguments: [
                .named(name: "name", value: bazelLabel(fromString: name).toSkylark()),
                .named(name: "bundle_imports",
                       value: bundleImports.map { GlobNode(include: Set($0)) }.toSkylark() )
                ])
    }

    static func extractBundleName(fromPath path: String) -> String {
        return path.components(separatedBy: "/").map { (s: String) in
            s.hasSuffix(".bundle") ? s : ""
            }.reduce("", +).replacingOccurrences(of: ".bundle", with: "")
    }

}


// https://github.com/bazelbuild/rules_apple/blob/0.13.0/doc/rules-resources.md#apple_resource_bundle
public struct AppleResourceBundle: BazelTarget {
    public let name: String
    let resources: AttrSet<[String]>

    public var acknowledged: Bool {
        return true
    }

    public func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "apple_resource_bundle",
            arguments: [
                .named(name: "name", value: bazelLabel(fromString: name).toSkylark()),
                .named(name: "resources",
                       value: resources.map { GlobNode(include: Set($0)) }.toSkylark() )
        ])
    }
}

// https://bazel.build/versions/master/docs/be/general.html#config_setting
public struct ConfigSetting: BazelTarget {
    public let name: String
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

// https://github.com/bazelbuild/rules_apple/blob/818e795208ae3ca1cf1501205549d46e6bc88d73/doc/rules-general.md#apple_static_framework_import
public struct AppleStaticFrameworkImport: BazelTarget {
    public let name: String // A unique name for this rule.
    let frameworkImports: AttrSet<[String]> // The list of files under a .framework directory which are provided to Objective-C targets that depend on this target.

    public var acknowledged: Bool {
        return true
    }

    // FIXME: provide an API for apple_dynamic_framework_import.
    // Assume that every framework is static.
    // Typically CocoaPods supports either dynamic or static,
    // so for the most part, this should be fine.
    // apple_static_framework_import(
    //     name = "OCMock",
    //     framework_imports = [
    //         glob(["iOS/OCMock.framework/**"]),
    //     ],
    //     visibility = ["visibility:public"]
    // )
    public func toSkylark() -> SkylarkNode {
        return SkylarkNode.functionCall(
                name: "apple_static_framework_import",
                arguments: [SkylarkFunctionArgument]([
                    .named(name: "name", value: .string(name)),
                    .named(name: "framework_imports",
                           value: frameworkImports.map {
                                  GlobNode(include: Set($0.map { $0 + "/**" }))
                            }.toSkylark()),
                    .named(name: "visibility", value: .list(["//visibility:public"]))
                ])
        )
    }
}

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_import
public struct ObjcImport: BazelTarget {
    public let name: String // A unique name for this rule.
    let archives: AttrSet<[String]> // The list of .a files provided to Objective-C targets that depend on this target.

    public var acknowledged: Bool {
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
    public let sourceFiles: AttrSet<GlobNode>
    public let headers: AttrSet<GlobNode>
    public let includes: [String]
    public let headerName: AttrSet<String>
    public let weakSdkFrameworks: AttrSet<[String]>
    public let sdkDylibs: AttrSet<[String]>
    public let bundles: AttrSet<[String]>
    public let resources: AttrSet<GlobNode>
    public let publicHeaders: AttrSet<Set<String>>
    public let nonArcSrcs: AttrSet<GlobNode>

    // only used later in transforms
    public let requiresArc: AttrSet<Either<Bool, [String]>?>

    // "var" properties are user configurable so we need mutation here
    public var sdkFrameworks: AttrSet<[String]>
    public var copts: AttrSet<[String]>
    public var deps: AttrSet<[String]>

    public let isTopLevelTarget: Bool
    public let externalName: String

    init(name: String,
        externalName: String,
        sourceFiles: AttrSet<GlobNode>,
        headers: AttrSet<GlobNode>,
        headerName: AttrSet<String>,
        includes: [String],
        sdkFrameworks: AttrSet<[String]>,
        weakSdkFrameworks: AttrSet<[String]>,
        sdkDylibs: AttrSet<[String]>,
        deps: AttrSet<[String]>,
        copts: AttrSet<[String]>,
        bundles: AttrSet<[String]>,
        resources: AttrSet<GlobNode>,
        publicHeaders: AttrSet<Set<String>>,
        nonArcSrcs: AttrSet<GlobNode>,
        requiresArc: AttrSet<Either<Bool, [String]>?>,
        isTopLevelTarget: Bool
    ) {
        self.name = name
        self.externalName = externalName
        self.headerName = headerName
        self.includes = includes
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

    /// Helper to allocate with a podspec
    /// objc_library is used for either C++ compilation or ObjC/C compilation.
    /// There is no way to have rule specific `cpp` opts in Bazel, so we need
    /// to split C++ and ObjC apart.
    // TODO: Add bazel-discuss thread on this matter.
    /// isSplitDep indicates if the library is a split language dependency
    init(parentSpecs: [PodSpec] = [], spec: PodSpec, extraDeps: [String] = [],
         isSplitDep: Bool = false,
         sourceType: BazelSourceLibType = .objc) {
        let fallbackSpec = FallbackSpec(specs: parentSpecs + [spec])

        isTopLevelTarget = parentSpecs.isEmpty && isSplitDep == false
        let allSourceFiles = spec.attr(\PodSpecRepresentable.sourceFiles).unpackToMulti()

        let includeFileTypes = sourceType == .cpp ? CppLikeFileTypes :
            ObjcLikeFileTypes
        let implFiles = extractFiles(fromPattern: allSourceFiles,
            includingFileTypes: includeFileTypes)
            .map { Set($0) }

        let allExcludes = fallbackSpec.attr(\.excludeFiles).unpackToMulti()
        let implExcludes = extractFiles(fromPattern: allExcludes,
            includingFileTypes: CppLikeFileTypes <> ObjcLikeFileTypes)
            .map { Set($0) }

        requiresArc = fallbackSpec.attr(\.requiresArc)
            .unpackToMulti().map {
                value in
                switch value {
                case let .left(value):
                    return .left(value)
                case let .right(value):
                    return .right(extractFiles(fromPattern: value,
                                               includingFileTypes: CppLikeFileTypes <> ObjcLikeFileTypes))
                default:
                    fatalError("X?")
                }
            }
        publicHeaders = fallbackSpec.attr(\PodSpecAttr.publicHeaders).map { Set($0) }

        let podName = GetBuildOptions().podName
        name = computeLibName(parentSpecs: parentSpecs, spec: spec, podName:
            podName, isSplitDep: isSplitDep, sourceType: sourceType)
        let externalName = parentSpecs.first?.name ?? spec.name

        let xcconfigTransformer =
            XCConfigTransformer.defaultTransformer(externalName: externalName,
                                                   sourceType: sourceType)

        /// TODO: This operation should operate on the AttrSet
        let xcconfigFlags =
            xcconfigTransformer.compilerFlags(forXCConfig: fallbackSpec.attr(\.podTargetXcconfig).basic ?? [:]) +
            xcconfigTransformer.compilerFlags(forXCConfig: fallbackSpec.attr(\.userTargetXcconfig).basic ?? [:]) +
            xcconfigTransformer.compilerFlags(forXCConfig: fallbackSpec.attr(\.xcconfig).basic ?? [:])

        let xcconfigCopts = xcconfigFlags.filter { !$0.hasPrefix("-I") }

        let moduleName: AttrSet<String> = fallbackSpec.attr(\.moduleName).map {
            $0 ?? ""
        }
        let headerDirectoryName: AttrSet<String?> = fallbackSpec.attr(\.headerDirectory)

        let headerName = (moduleName.isEmpty ? nil : moduleName) ??
            (headerDirectoryName.basic == nil ? nil :
                headerDirectoryName.denormalize()) ?? AttrSet<String>(value:
                externalName)

        let includePodHeaderDirs: (() -> [String]) = {
            let options = GetBuildOptions()
            if options.generateHeaderMap {
                return []
            }
            let value = spec.podTargetXcconfig?["USE_HEADERMAP"]
            let include = value == nil || (value?.lowercased() != "no" &&
                value?.lowercased() != "false")
            guard include else { return [String]() }

            return [getPodBaseDir() + "/" + podName + "/" + PodSupportSystemPublicHeaderDir]
        }

        includes = xcconfigFlags.filter { $0.hasPrefix("-I") }.map {
            String($0.dropFirst(2))
        } + includePodHeaderDirs()
        self.headerName = headerName
        self.externalName = externalName

        sourceFiles = implFiles.zip(implExcludes).map {
            t -> GlobNode in
            GlobNode(include: .left(t.first ?? Set()), exclude: .left(t.second ?? Set()))
        }

        // Build out header files
        let getHeaderDirHeaders = {
            () -> AttrSet<[String]> in
            guard !headerDirectoryName.isEmpty else {
                return AttrSet<[String]>.empty
            }
            let pattern = headerDirectoryName.map {
                (name: String?) -> [String] in
                guard let name = name else {
                    return []
                }
                return [name + "/**"]
            }
            return extractFiles(fromPattern: pattern,
                                includingFileTypes: HeaderFileTypes)
        }
        let privateHeaders = fallbackSpec.attr(\.privateHeaders).unpackToMulti()
        // It's possible to use preserve_paths for header includes
        // also, preserve path may be used for a file, so we'd need to touch
        // the FS here to actually find out.
        let preservePaths = fallbackSpec.attr(\.preservePaths).unpackToMulti().map { $0.filter { !$0.contains("LICENSE") } }

        // This is emitting a problematic header ( duplicate includes )
        let headerDirs: AttrSet<[String]> = getHeaderDirHeaders().unpackToMulti()
        let allSpecHeadersList: AttrSet<[String]> = headerDirs <>
            extractFiles(fromPattern: allSourceFiles, includingFileTypes:
                HeaderFileTypes) <>
            extractFiles(fromPattern: privateHeaders, includingFileTypes:
                HeaderFileTypes) <>
            extractFiles(fromPattern: preservePaths, includingFileTypes:
                HeaderFileTypes)

        let allSpecHeaders = allSpecHeadersList.map { Set($0) }
        let headerExcludes = extractFiles(fromPattern: allExcludes,
                                          includingFileTypes: HeaderFileTypes).map { Set($0) }

        headers = allSpecHeaders.zip(headerExcludes).map {
            t -> GlobNode in
            GlobNode(include: Set(t.first ?? []), exclude: Set(t.second
                    ?? []))
        }
        nonArcSrcs = AttrSet.empty
        sdkFrameworks = fallbackSpec.attr(\.frameworks)

        weakSdkFrameworks = fallbackSpec.attr(\.weakFrameworks)

        sdkDylibs = fallbackSpec.attr(\.libraries)

        // Lift the deps to multiplatform, then get the names of these deps.
        let mpDeps = fallbackSpec.attr(\.dependencies)
        let mpPodSpecDeps = mpDeps.map { $0.map {
            getDependencyName(fromPodDepName: $0, podName:
                podName)
        } }

        let extraDepNames = extraDeps.map { bazelLabel(fromString: ":\($0)") }

        deps = AttrSet(basic: extraDepNames) <> mpPodSpecDeps

        copts = AttrSet(basic: xcconfigCopts.sorted(by: <)) <> fallbackSpec.attr(\.compilerFlags)

        // Select resources that are not prebuilt bundles
        let resourceFiles = (spec.attr(\.resources).map { (strArr: [String]) -> [String] in
            strArr.filter { (str: String) -> Bool in
                !str.hasSuffix(".bundle")
            }

        }).map(extractResources)
        resources = resourceFiles.map { GlobNode(include: Set($0)) }

        let prebuiltBundles = spec.attr(\.resources).map { (strArr: [String]) -> [String] in
            strArr.filter { (str: String) -> Bool in
                str.hasSuffix(".bundle")
            }
            .map(AppleBundleImport.extractBundleName)
            .map { k in ":\(spec.moduleName ?? spec.name)_Bundle_\(k)" }
            .map(bazelLabel)
        }

        let resourceBundles = spec.attr(\.resourceBundles)
            .map { dict in
                Array(dict.keys)
                    .map { k in ":\(spec.moduleName ?? spec.name)_Bundle_\(k)" }
                    .map(bazelLabel)
            }

        bundles = prebuiltBundles <> resourceBundles
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

    /// Source file logic
    /// lib/cocoapods/sandbox/file_accessor.rb
    ///      def source_files
    ///          paths_for_attribute(:source_files)
    ///      end
    ///
    ///      def non_arc_source_files
    ///        source_files - arc_source_files
    ///      end
    ///
    ///      def arc_source_files
    ///        case spec_consumer.requires_arc
    ///        when TrueClass
    ///          source_files
    ///        when FalseClass
    ///          []
    ///        else
    ///          paths_for_attribute(:requires_arc) & source_files
    ///        end
    ///      end
    ///
    /// paths_for_attrs has an exclude on it..
    /// non_arc_source_files may not have it in some cases?
    ///
    /// consumer is in a different repo
    //// github.com/CocoaPods/Core/blob/master/lib/cocoapods-core/specification/consumer.rb
    /// 
    /// requires_arc ends up getting the excludes applied _before the union with
    /// source fies.
    /// 
    ///
    /// The & operator is a union in ruby means:
    /// [1,2] & [1] = [1]
    /// [1,2] & [] = []
    ///
    /// This simply means that you need to have source files.
    ///
    /// In other words
    /// We can take
    /// Total = Left + Right
    /// 
    /// Glob(include, exclude)
    /// a = 1, 2, 3
    /// b = 2, 4, 6
    /// we'd want 2
    /// 
    /// We can implement this operator in Bazel as
    /// a - ( a - b )
    /// Or Glob(include: a, exclude(Glob(include: a, exclude: Glob(b) ) ))

    // MARK: Source Excludable

    func addExcluded(targets: [BazelTarget]) -> BazelTarget {
        let sourcesToExclude: [AttrSet<GlobNode>] = targets.compactMap {
            target -> AttrSet<GlobNode>? in
            guard let excludableTarget = target as? ObjcLibrary else {
                return nil
            }
            if excludableTarget.name == self.name {
                return nil
            }
            return excludableTarget.sourceFiles
        }
        // Need to sequence this..
        // This operation pushes up excludes from the depedee's sourceFiles.include
        // Sequence all of the source files
        let allExcludes: AttrSet<[GlobNode]>
        allExcludes = sourcesToExclude.reduce(AttrSet<[GlobNode]>.empty) {
            accum, next -> AttrSet<[GlobNode]> in
            let nextV: AttrSet<GlobNode> = next
            return accum.zip(nextV).map { zip in
                let first = zip.first ?? []
                guard let second = zip.second else {
                    return first
                }
                return first + [second]
            }
        }

        let sourcesWithExcludes: AttrSet<GlobNode>
        sourcesWithExcludes = sourceFiles.zip(allExcludes).map {
            attrTuple -> GlobNode in
            // We need a non trivial representation of propgating globs.
            // This might require glob to be some abstract container
            guard let accumSource = attrTuple.first else {
                return GlobNode()
            }
            guard let excludedTargetSources: [GlobNode] = attrTuple.second else {
                return accumSource
            }
            let append: [Either<Set<String>, GlobNode>] = excludedTargetSources.map {
                .right($0)
            }
            return GlobNode(include: accumSource.include, exclude:
                accumSource.exclude + append)
        }
        let requiresArcValue: AttrSet<Either<Bool, [String]>?> = requiresArc
        let arcSources: AttrSet<GlobNode>
        arcSources = sourcesWithExcludes.zip(requiresArcValue).map {
            attrTuple -> GlobNode in
            let arcSources = attrTuple.first ?? GlobNode()
            guard let requiresArcSources = attrTuple.second else {
                return arcSources
            }
            switch requiresArcSources {
            case let .left(boolValue):
                return boolValue ? arcSources : GlobNode()
            case let .right(patternsValue):
                // In cocoapods this is:
                // As we don't have the union in skylark, this implements the
                // union operator with glob ( see above comment )
                // ruby: paths_for_attribute(:requires_arc) & source_files
                return GlobNode(include: .left(Set(patternsValue)),
                    exclude:.right(GlobNode(include: .left(Set(patternsValue)),
                         exclude:.right(arcSources))))
            default:
                fatalError("null logic error")
            }
        }
        let nonArcSources: AttrSet<GlobNode>
        nonArcSources = sourcesWithExcludes.zip(arcSources).map {
            attrTuple -> GlobNode in
            guard let all = attrTuple.first else {
                if let arcSourcesVal = attrTuple.second {
                    return arcSourcesVal
                }
                fatalError("null logic error")
            }

            guard let arcSources = attrTuple.second else {
                return attrTuple.first ?? GlobNode()
            }
            return GlobNode(include: .right(all), exclude: .right(arcSources))
        }
        let lib = self
        return ObjcLibrary(name: lib.name, externalName: lib.externalName,
                           sourceFiles: arcSources, headers: lib.headers,
                           headerName: lib.headerName, includes: lib.includes,
                           sdkFrameworks: lib.sdkFrameworks, weakSdkFrameworks:
                           lib.weakSdkFrameworks, sdkDylibs: lib.sdkDylibs, deps:
                           deps, copts: lib.copts, bundles: lib.bundles, resources:
                           lib.resources, publicHeaders: lib.publicHeaders,
                           nonArcSrcs: nonArcSources, requiresArc:
                           lib.requiresArc, isTopLevelTarget: lib.isTopLevelTarget)
    }

    // MARK: BazelTarget

    public var acknowledgedDeps: [String]? {
        let basic = deps.basic ?? [String]()
        let multiios = deps.multi.ios ?? [String]()
        let multiosx = deps.multi.osx ?? [String]()
        let multitvos = deps.multi.tvos ?? [String]()

        return Array(Set(basic + multiios + multiosx + multitvos))
    }

    public var acknowledged: Bool {
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
        let lib = self
        let nameArgument = SkylarkFunctionArgument.named(name: "name", value: .string(lib.name))

        var inlineSkylark = [SkylarkNode]()
        var libArguments = [SkylarkFunctionArgument]()

        libArguments.append(nameArgument)
        
        let enableModulesSkylark = SkylarkFunctionArgument.named(name: "enable_modules",
                                                          value: enableModules ? .int(1) : .int(0))
        libArguments.append(enableModulesSkylark)

        let moduleName = bazelModuleName()

        // note: trans headers aren't propagated here. The code requires that
        // all deps are declared in the PodSpec.
        // Depend on header file groups for ObjcLibrary's in this build file
        let depHdrs = deps.map {
            $0.filter { depLabelName -> Bool in
                guard depLabelName.hasPrefix(":") else {
                    return false
                }
                let offsetIdx = depLabelName.utf8
                        .index(depLabelName.utf8.startIndex, offsetBy: 1)
                let labelName = String(
                        depLabelName[offsetIdx ..< depLabelName.utf8.endIndex])
                let target = BuildFileContext.get()?.getBazelTarget(name:
                        labelName)
                return target is ObjcLibrary
            }.map { ($0 + "_hdrs").toSkylark() }
        }
       
        let podSupportHeaders: SkylarkNode
        podSupportHeaders = GlobNode(include: [PodSupportSystemPublicHeaderDir + "**/*"])
        .toSkylark()
        if lib.isTopLevelTarget {
            var exposedHeaders: SkylarkNode = podSupportHeaders .+.
                headers.toSkylark() .+. depHdrs.toSkylark()
            inlineSkylark.append(.functionCall(
                name: "filegroup",
                arguments: [
                    .named(name: "name", value: (externalName + "_hdrs").toSkylark()),
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

            // Union headers: it's possible, that some spec headers will not be
            // include in the TopLevelTarget headers: e.g. when a spec is not a
            // dep of the TopLevelTarget.  Additionally, we can include headers
            // multiple times, and Bazel will emit warnings if they aren't
            // union'd
            inlineSkylark.append(.functionCall(
                name: "filegroup",
                arguments: [
                    .named(name: "name", value: (name + "_union_hdrs").toSkylark()),
                    .named(name: "srcs", value: [
                        name + "_hdrs",
                        externalName + "_hdrs",
                    ].toSkylark()),
                    .named(name: "visibility", value:
                        ["//visibility:public"].toSkylark()),
                ]
            ))
        }

        let baseHeaders: [String] = isTopLevelTarget ?
            [":" + externalName + "_hdrs"] : [":" + name + "_union_hdrs"]

        inlineSkylark.append(.functionCall(
            name: "headermap",
            arguments: [
                .named(name: "name", value: (name + "_hmap").toSkylark()),
                .named(name: "namespace", value: moduleName.toSkylark()),
                .named(name: "hdrs", value: baseHeaders.toSkylark()),
                // TODO: in some cases, we may need to break this invariant, as
                // it may not hold true for all cocoapods ( e.g. give it all
                // possibilities here )
                .named(name: "deps", value: deps.sorted(by: <).toSkylark()),
                .named(name: "visibility", value: ["//visibility:public"].toSkylark()),
            ]
        ))

        if lib.includes.count > 0 {
            inlineSkylark.append(.functionCall(
                name: "gen_includes",
                arguments: [
                    .named(name: "name", value: (name + "_includes").toSkylark()),
                    .named(name: "include", value: includes.toSkylark()),
                ]
            ))
        }

        let moduleMapDirectoryName = externalName + "_module_map"
        let clangModuleName = headerName.basic?.replacingOccurrences(of: "-", with: "_")
        if lib.isTopLevelTarget {
            inlineSkylark.append(.functionCall(
                name: "gen_module_map",
                arguments: [
                    .basic(moduleName.toSkylark()),
                    .basic(moduleMapDirectoryName.toSkylark()),
                    .basic(clangModuleName.toSkylark()),
                    .basic([externalName + "_hdrs"].toSkylark())
                ]
                ))
             if lib.externalName != lib.name {
                 inlineSkylark.append(makeAlias(name: lib.externalName, actual:
                             lib.name))
             }
        }
        
        if !lib.sourceFiles.isEmpty {
            libArguments.append(.named(
                name: "srcs",
                value: lib.sourceFiles.toSkylark()
                ))
        }
        if !lib.nonArcSrcs.isEmpty {
            libArguments.append(.named(
                name: "non_arc_srcs",
                value: lib.nonArcSrcs.toSkylark()
            ))
        }

        func buildPCHList(sources: GlobNode) -> GlobNode {
            // Note: this PCH search looks in source file paths adjacent to
            // source files.
            let nestedComponents: [Either<Set<String>, GlobNode>] = sources.include.map {
                incValue -> Either<Set<String>, GlobNode> in
                incValue.map {
                    pattern -> String in
                    let components = URL(fileURLWithPath: pattern)
                        .deletingPathExtension()
                        .appendingPathExtension("pch")
                        .relativePath
                        .components(separatedBy: "/")
                    return [components.first ?? "", "**", "*.pch"].joined(separator: "/")
                }
            }
            return GlobNode(include: nestedComponents, exclude: [])
        }

        func getPCHSkylark(sourcePaths: GlobNode?) -> SkylarkNode {
            return .functionCall(
                // Call internal function to find a PCH.
                // @see workspace.bzl
                name: "pch_with_name_hint",
                arguments: [
                    .basic(.string(lib.externalName)),
                    .basic((sourcePaths ?? GlobNode()).toSkylark()),
                ]
            )
        }

        // let pchSourcePaths = (lib.sourceFiles <> lib.nonArcSrcs).map {
        let pchSourcePaths = lib.sourceFiles.map {
            buildPCHList(sources: $0)
        }.flattenToBasicIfPossible()

        let pchSkylark: SkylarkNode
        if pchSourcePaths.isEmpty {
            pchSkylark = getPCHSkylark(sourcePaths: nil)
        } else {
            // The empty value for rendering a glob is []
            // We need to render a non for //conditions:default
            if pchSourcePaths.multi.isEmpty {
                pchSkylark = getPCHSkylark(sourcePaths: pchSourcePaths.basic)
            } else {
                let multi = pchSourcePaths.multi
                let arg = [
                    ":\(SelectCase.osx.rawValue)": getPCHSkylark(sourcePaths: multi.osx),
                    ":\(SelectCase.tvos.rawValue)": getPCHSkylark(sourcePaths: multi.tvos),
                    ":\(SelectCase.watchos.rawValue)": getPCHSkylark(sourcePaths: multi.watchos),
                    "\(SelectCase.fallback.rawValue)": getPCHSkylark(sourcePaths: multi.ios),
                ]
                pchSkylark = SkylarkNode.functionCall(name: "select", arguments: [
                    .basic(arg.toSkylark()),
                ])
            }
        }

        let moduleHeaders: [String] = generateModuleMap ?
            [":" + moduleMapDirectoryName + "_module_map_file"] : []
        libArguments.append(.named(
            name: "hdrs",
            value: (baseHeaders + moduleHeaders + (options.generateHeaderMap ? [":" + name + "_hmap"] : [])).toSkylark()
        ))

        libArguments.append(.named(
            name: "pch",
            value: pchSkylark
        ))
        if generateModuleMap {
            // Include the public headers which are symlinked in
            // All includes are bubbled up automatically
            libArguments.append(.named(
                name: "includes",
                value: [moduleMapDirectoryName].toSkylark()
            ))
        }

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

        var allDeps: SkylarkNode = SkylarkNode.empty
        if !lib.deps.isEmpty {
            allDeps = lib.deps.sorted(by: (<)).toSkylark() 
        }
        if lib.includes.count > 0 {
            allDeps = allDeps .+. [":\(name)_includes"].toSkylark()
        }
        if options.generateHeaderMap {
            allDeps = allDeps .+. [":" + name + "_hmap"].toSkylark()
        }

        if allDeps.isEmpty == false { 
            libArguments.append(.named(
                name: "deps",
                value: allDeps
            ))
        }

        let buildConfigDependenctCOpts =
            SkylarkNode.functionCall(name: "select",
                                     arguments: [
                                         .basic([
                                             ":release":
                                                 ["-DPOD_CONFIGURATION_RELEASE=1", "-DNS_BLOCK_ASSERTIONS=1"],
                                             "//conditions:default":
                                                 ["-DPOD_CONFIGURATION_RELEASE=0"],
                                         ].toSkylark()
                                         ),
                                     ])
        let getPodIQuotes = {
            () -> [String] in
            if options.generateHeaderMap {
                return [
                    "-I$(GENDIR)/\(getGenfileOutputBaseDir())/" + lib.name + "_hmap.hmap",
                    "-I.",
                ]
            }
            let podInclude = lib.includes.first(where: {
                $0.contains(PodSupportSystemPublicHeaderDir)
            })
            guard podInclude != nil else { return [] }

            let headerDirs = self.headerName.map { PodSupportSystemPublicHeaderDir + "\($0)/" }
            let headerSearchPaths: Set<String> = Set(headerDirs.fold(
                basic: { str in Set<String>([str].compactMap { $0 }) },
                multi: {
                    (result: Set<String>, multi: MultiPlatform<String>)
                        -> Set<String> in
                    result.union([multi.ios, multi.osx, multi.watchos, multi.tvos].compactMap { $0 })
                }
            ))
            return headerSearchPaths
                .sorted(by: <)
                .reduce([String]()) {
                    accum, searchPath in
                    // Assume that the podspec matches the name of the directory.
                    // it is a convention that these are 1 in the same.
                    let podName = GetBuildOptions().podName
                    return accum + ["-I\(getPodBaseDir())/\(podName)/\(searchPath)"]
                }
        }

        libArguments.append(.named(
            name: "copts",
            value: (lib.copts.toSkylark() .+. buildConfigDependenctCOpts .+. getPodIQuotes().toSkylark()
            ) <> ["-fmodule-name=" + moduleName + "_pod_module"].toSkylark()
        ))

        if !lib.bundles.isEmpty || !lib.resources.isEmpty {
            let dataVal: SkylarkNode = [
                lib.bundles.isEmpty ? nil : lib.bundles.sorted(by: { (s1, s2) -> Bool in
                    s1 < s2
                }).toSkylark(),
                lib.resources.isEmpty ? nil : lib.resources.toSkylark(),
            ]
            .compactMap { $0 }
            .reduce([].toSkylark()) { (res, node) -> SkylarkNode in
                if res.isEmpty {
                    return node
                }
                if node.isEmpty {
                    return res
                }
                return res .+. node
            }
            libArguments.append(.named(name: "data",
                                       value: dataVal.toSkylark()))
        }

        libArguments.append(.named(
            name: "visibility",
            value: ["//visibility:public"].toSkylark()
        ))
        return .lines(inlineSkylark + [.functionCall(name: "objc_library", arguments: libArguments)])
    }
}

// FIXME: Clean these up and move to RuleUtils
private func extractResources(patterns: [String]) -> [String] {
    return patterns.flatMap { (p: String) -> [String] in
        pattern(fromPattern: p, includingFileTypes: [])
    }
}
