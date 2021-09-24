//
//  Pod.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

private var sharedBuildOptions: BuildOptions = BasicBuildOptions.empty

public func GetBuildOptions() -> BuildOptions {
    return sharedBuildOptions
}

/// Config Setting Nodes
/// Write Build dependent COPTS.
/// @note We consume this as an expression in ObjCLibrary
public func makeConfigSettingNodes() -> SkylarkNode {
    let comment = [
        "# Add a config setting release for compilation mode",
        "# Assume that people are using `opt` for release mode",
        "# see the bazel user manual for more information",
        "# https://docs.bazel.build/versions/master/be/general.html#config_setting",
    ].map { SkylarkNode.skylark($0) }
    return .lines([.lines(comment),
        ConfigSetting(
            name: "release",
            values: ["compilation_mode": "opt"]).toSkylark(),
        ConfigSetting(
            name: "osxCase",
            values: ["apple_platform_type": "macos"]).toSkylark(),
        ConfigSetting(
            name: "tvosCase",
            values: ["apple_platform_type": "tvos"]).toSkylark(),
        ConfigSetting(
            name: "watchosCase",
            values: ["apple_platform_type": "watchos"]).toSkylark()
    ])
}

public func makeLoadNodes(forConvertibles skylarkConvertibles: [SkylarkConvertible]) -> SkylarkNode {
    let hasSwift = skylarkConvertibles.first(where: { $0 is SwiftLibrary }) != nil
    let hasAppleBundleImport = skylarkConvertibles.first(where: { $0 is AppleBundleImport }) != nil
    let hasAppleResourceBundle = skylarkConvertibles.first(where: { $0 is AppleResourceBundle }) != nil
    let hasAppleFrameworkImport = skylarkConvertibles.first(where: { $0 is AppleFrameworkImport }) != nil
    let isDynamicFramework = GetBuildOptions().isDynamicFramework
    
    return .lines( [
        hasSwift ?  SkylarkNode.skylark("load('@build_bazel_rules_swift//swift:swift.bzl', 'swift_library')") : nil,
        hasAppleBundleImport ?  SkylarkNode.skylark("load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_bundle_import')") : nil,
        hasAppleResourceBundle ?  SkylarkNode.skylark("load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_resource_bundle')") : nil,
        hasAppleFrameworkImport && isDynamicFramework ?  SkylarkNode.skylark("load('@build_bazel_rules_apple//apple:apple.bzl', 'apple_dynamic_framework_import')") : nil,
        hasAppleFrameworkImport && !isDynamicFramework ?  SkylarkNode.skylark("load('@build_bazel_rules_apple//apple:apple.bzl', 'apple_static_framework_import')") : nil,
        ].compactMap { $0 }
    )
}

// Make Nodes to be inserted at the beginning of skylark output
// public for test purposes
public func makePrefixNodes() -> SkylarkNode {
    let name = "rules_pods"
    let extFile = getRulePrefix(name: name) + "BazelExtensions:extensions.bzl"

    let lineNodes = [
        SkylarkNode.functionCall(name: "load", arguments: [
            .basic(.string(extFile)),
            .basic(.string("acknowledged_target")),
            .basic(.string("gen_module_map")),
            .basic(.string("gen_includes")),
            .basic(.string("headermap")),
            .basic(.string("umbrella_header"))]),
        makeConfigSettingNodes()
    ]
    return .lines(lineNodes)
}

/// Acknowledgment node exposes an acknowledgment fragment including all of
/// the `deps` acknowledgment fragments.
public struct AcknowledgmentNode: BazelTarget {
    public let name: String
    let license: PodSpecLicense
    let deps: [String]

    public func toSkylark() -> SkylarkNode {
        let nodeName = bazelLabel(fromString: name).toSkylark()
        let options = GetBuildOptions()
        let podSupportBuildableDir = String(PodSupportBuidableDir.utf8.dropLast())!
        let value = (getRulePrefix(name: options.podName) +
                        podSupportBuildableDir + ":acknowledgement_fragment")
        let target = SkylarkNode.functionCall(
            name: "acknowledged_target",
            arguments: [
                .named(name: "name", value: nodeName),
                // Consider moving this to an aspect and adding it to the
                // existing dep graph.
                .named(name: "deps", value: deps.map { $0 + "_acknowledgement" }.toSkylark()),
                .named(name: "value", value: value.toSkylark())
            ]
        )
        return target
    }
}
public struct PodBuildFile: SkylarkConvertible {
    /// Skylark Convertibles excluding prefix nodes.
    /// @note Use toSkylark() to generate the actual BUILD file
    public let skylarkConvertibles: [SkylarkConvertible]

    /// When there is a podspec adjacent to another, we need to concat
    /// the "child" BUILD file into the parents
    public let assimilate: Bool

    private let options: BuildOptions

    public static func shouldAssimilate(buildOptions: BuildOptions) -> Bool {
        return buildOptions.path != "." &&
            FileManager.default.fileExists(atPath: BazelConstants.buildFilePath)
    }

    /// Return the skylark representation of the entire BUILD file
    public func toSkylark() -> SkylarkNode {
        let prevOptions = sharedBuildOptions
        // This is very brittle but the options are implicit passed into
        // toSkylark() and constructors instead of passing them to every
        // function. For child build files we need to update them.
        sharedBuildOptions = options
        BuildFileContext.set(BuildFileContext(convertibles: skylarkConvertibles))
        let convertibleNodes: [SkylarkNode] = skylarkConvertibles.compactMap { $0.toSkylark() }
        BuildFileContext.set(nil)

        let prefixNodes: [SkylarkNode]
        // If we have to assimilate this into another build file then don't
        // write prefix nodes. This is not 100% pefect, as some other algorithms
        // require all contents of the build file. This is an intrim solution.
        let allHeaders = skylarkConvertibles.reduce(into: [String]()) {
            accum, next in
            if let objcLib = next as? ObjcLibrary {
                accum.append(objcLib.name + "_direct_hdrs")
            }
        }

        let pkgHeaders = SkylarkNode.functionCall(
            name: "filegroup",
            arguments: [
                .named(name: "name", value: (getNamePrefix() +
                                             options.podName + "_package_hdrs").toSkylark()),
                .named(name: "srcs", value: allHeaders.toSkylark()),
                .named(name: "visibility", value: ["//visibility:public"].toSkylark()),
                ]
            )
    
        sharedBuildOptions = prevOptions
        let top: [SkylarkNode] = assimilate ? [] : [makePrefixNodes()]
        prefixNodes = top + [pkgHeaders]
        return .lines([ makeLoadNodes(forConvertibles: skylarkConvertibles) ] +
            prefixNodes
            + convertibleNodes)
    }

    public static func with(podSpec: PodSpec, buildOptions: BuildOptions =
                            BasicBuildOptions.empty, assimilate: Bool = false) -> PodBuildFile {
        sharedBuildOptions = buildOptions
        let libs = PodBuildFile.makeConvertables(fromPodspec: podSpec, buildOptions: buildOptions)
        return PodBuildFile(skylarkConvertibles: libs, assimilate: assimilate,
                            options: buildOptions)
    }

    private static func bundleLibraries(withPodSpec spec: PodSpec) -> [BazelTarget] {
        // See if the Podspec specifies a prebuilt .bundle file
        let bundleResources = (spec.attr(\.resources)).map { (strArr: [String]) -> [BazelTarget] in
            strArr.filter({ (str: String) -> Bool in
                str.hasSuffix(".bundle")
            }).map { (bundlePath: String) -> BazelTarget in
                let bundleName = AppleBundleImport.extractBundleName(fromPath: bundlePath)
                let name = "\(spec.moduleName ?? spec.name)_Bundle_\(bundleName)"
                let bundleImports = AttrSet<[String]>(basic: ["\(bundlePath)/**"])
                return AppleBundleImport(name: name, bundleImports: bundleImports)
            }
        }

        // Converts an attrset to resource bundles
        let resourceBundles = spec.attr(\.resourceBundles).map {
            return $0.map {
            (x: (String, [String])) -> BazelTarget  in
            let k = x.0
            let resources = x.1
            let name = "\(spec.moduleName ?? spec.name)_Bundle_\(k)"
            return AppleResourceBundle(name: name, resources: AttrSet<[String]>(basic: resources))
        }
        }

        return ((resourceBundles.basic ?? []) + (resourceBundles.multi.ios ??
        []) + (bundleResources.basic ?? []) + (bundleResources.multi.ios ?? [])).sorted { $0.name < $1.name }
    }

    private static func vendoredFrameworks(withPodspec spec: PodSpec) -> [BazelTarget] {
        let frameworks = spec.attr(\.vendoredFrameworks)
        return frameworks.isEmpty ? [] : [AppleFrameworkImport(name: "\(spec.moduleName ?? spec.name)_VendoredFrameworks", frameworkImports: frameworks)]
    }

    private static func vendoredLibraries(withPodspec spec: PodSpec) -> [BazelTarget] {
        let libraries = spec.attr(\.vendoredLibraries)
        return libraries.isEmpty ? [] : [ObjcImport(name: "\(spec.moduleName ?? spec.name)_VendoredLibraries", archives: libraries)]
    }

    private static func getOwnSourceTypes(fromPodspec spec: PodSpec) ->
        Set<BazelSourceLibType> {
        let sources = spec.attr(\.sourceFiles)
        let arcSources = spec.attr(\.requiresArc).map {
            srcs -> [String] in
            if case let .right(srcsVal) = srcs {
                return srcsVal
            }
            return []
        }

        let objcLike = extractFiles(fromPattern: sources <> arcSources,
            includingFileTypes: ObjcLikeFileTypes)
        var result: Set<BazelSourceLibType> = Set()
        if !objcLike.isEmpty {
            result.insert(.objc)
        }

        let cppLike = extractFiles(fromPattern: sources <> arcSources, includingFileTypes:
                CppLikeFileTypes)
        if !cppLike.isEmpty {
            result.insert(.cpp)
        }

        if SwiftLibrary.hasSwiftSources(spec: spec) {
            result.insert(.swift)
        }
        return result
    }

    private static func getSourceTypes(fromPodspec spec: PodSpec) -> Set<BazelSourceLibType> {
        let sourceTypes = PodBuildFile.getOwnSourceTypes(fromPodspec: spec)
        return sourceTypes <> spec.selectedSubspecs().reduce(Set<BazelSourceLibType>()) {
            $0 <> PodBuildFile.getOwnSourceTypes(fromPodspec: $1)
        }
    }

    /// Construct source libs
    /// Depending on the source files and other factors, we'll return different
    /// kinds of rules for a PodSpec and corresponding SubSpecs
    static func makeSourceLibs(parentSpecs: [PodSpec], spec: PodSpec,
            extraDeps: [BazelTarget], isRootSpec: Bool = false) -> [BazelTarget] {
        var sourceLibs: [BazelTarget] = []
        let sourceTypes = getSourceTypes(fromPodspec: spec)
        let rootSpec = parentSpecs.first ?? spec
        let packageSourceTypes = getSourceTypes(fromPodspec: rootSpec)
        let fallbackSpec = FallbackSpec(specs: [spec] +  parentSpecs)

        let externalName = getNamePrefix() + (parentSpecs.first?.name ?? spec.name)
        let moduleName: AttrSet<String> = fallbackSpec.attr(\.moduleName).map {
            $0 ?? ""
        }
        let headerDirectoryName: AttrSet<String?> = fallbackSpec.attr(\.headerDirectory)
        let headerName = (moduleName.isEmpty ? nil : moduleName) ??
            (headerDirectoryName.basic == nil ? nil :
                headerDirectoryName.denormalize()) ?? AttrSet<String>(value:
                externalName)
        let clangModuleName = headerName.basic?.replacingOccurrences(of: "-", with: "_") ?? ""
        let isTopLevelTarget = parentSpecs.isEmpty
        let options = GetBuildOptions()

        let podName = GetBuildOptions().podName
        let rootName = computeLibName(parentSpecs: [], spec: rootSpec, podName:
            podName, isSplitDep: false, sourceType: .objc)

        let includes = ObjcLibrary(parentSpecs: parentSpecs, spec:
            spec).includes
        let hadImportedModuleMap = includes.reduce(into: false) {
            accum, next in
            // Note: for now we replace these module maps. There is a few issues
            // with accepting use provided module maps with static librares.
            // Assume that the headers are modular. This isn't gaurenteed,
            // however, CocoaPods does generate a module map with these headers.
            let moduleMapPath = "../../" + next + "/module.modulemap"
            if FileManager.default.fileExists(atPath: moduleMapPath) {
                try? FileManager.default.removeItem(atPath: moduleMapPath)
                accum = true
            }
        }

        let publicHeaders = rootName + "_public_hdrs" 
        // For swift, always use an umbrella import to impliclty load UIKit like
        // CocoaPods. The empty umbrella will have this
        // Note: we probably can do without this, but it replicates the behavior
        // of CocoaPods + Xcode which requires other to merge.
        // Consider adding a PCH header file into the module map
        let umbrellaHeader: UmbrellaHeader = {
            UmbrellaHeader(
                name: clangModuleName + "_umbrella_header",
                headers: [publicHeaders]
            )
        }()

        let swiftModuleMap: ModuleMap = {
            ModuleMap(
                name: clangModuleName + "_module_map",
                moduleName: clangModuleName,
                headers: [publicHeaders],
                moduleMapName: clangModuleName + ".modulemap",
                umbrellaHeader: umbrellaHeader.name
            )
        }()

        let objcModuleMap: ModuleMap?
        let hasSwift = packageSourceTypes.contains(.swift)
        if hasSwift {
            // When there is swift and Objc
            // - generate a module map
            // - extend the module map with the generated swift header
            objcModuleMap = ModuleMap(
                name: clangModuleName + "_extended_module_map",
                moduleName: clangModuleName,
                headers: [publicHeaders],
                swiftHeader: "../" + clangModuleName + "-Swift.h"
            )
        } else if hadImportedModuleMap || options.generateModuleMap {
            objcModuleMap = ModuleMap(
                name: clangModuleName + "_module_map",
                moduleName: clangModuleName,
                headers: [publicHeaders]
            )
        } else {
            objcModuleMap = nil
        }

        let moduleMapTargets: [BazelTarget] = 
            (hasSwift ? [swiftModuleMap, umbrellaHeader] : []) +
            (objcModuleMap != nil ? [objcModuleMap!] : [])
        // If there is an extended module map, we need a dependency on the
        // swift lib to generate the -Swift header
        let extraDepNames = extraDeps.map { $0.name }
        let extraObjcDepNames = extraDepNames
            + (hasSwift ? [rootName + "_swift"] : [])

        if sourceTypes.count == 0 {
            sourceLibs.append(ObjcLibrary(parentSpecs: parentSpecs, spec: spec,
                        extraDeps: extraObjcDepNames, sourceType:
                        .objc, moduleMap: objcModuleMap))
        } else if sourceTypes.count == 1 && sourceTypes.first != .swift {
            // For swift, we _always_ generate a top level ObjcLibrary for now.
            // Currently, the top level ObjcLibray is used to propagate module
            // maps upwards, and there is no dependency on the module map due to
            // mixed modules. The following code is dead
            if sourceTypes.first == .swift {
                if isTopLevelTarget {
                    sourceLibs.append(SwiftLibrary(parentSpecs: parentSpecs, spec: spec,
                                extraDeps: extraDepNames,
                                moduleMap: swiftModuleMap))
            
                }
            } else {
                sourceLibs.append(ObjcLibrary(parentSpecs: parentSpecs, spec: spec,
                            extraDeps: extraObjcDepNames,
                            sourceType: sourceTypes.first!, moduleMap: objcModuleMap))
            }
        } else {
            // Split out Cpp and Swift libraries into seperate libraries
            // The Objective-C libarary is the parent library ATM - is that
            // applicable for all cases?
            var splitDeps: [BazelTarget] = []

            if sourceTypes.contains(.cpp) {
                let cppLib = ObjcLibrary(parentSpecs: parentSpecs, spec: spec,
                        extraDeps: extraDeps.map { $0.name },
                        isSplitDep: true, sourceType: .cpp, moduleMap: objcModuleMap)
                splitDeps.append(cppLib)
                sourceLibs.append(cppLib)
            }

            if isTopLevelTarget && sourceTypes.contains(.swift) {
                // Append a swift library.
                let swiftLib = SwiftLibrary(parentSpecs: parentSpecs, spec: spec,
                        extraDeps: extraDepNames,
                        isSplitDep: true, moduleMap: swiftModuleMap)
                splitDeps.append(swiftLib)
                sourceLibs.append(swiftLib)
            }

            // In this case, the root lib is Objc
            let rootLib = ObjcLibrary(parentSpecs: parentSpecs, spec: spec,
                    extraDeps: extraObjcDepNames + (splitDeps.map { $0.name }),
                    moduleMap: objcModuleMap)
            sourceLibs.append(rootLib)
        }
        return sourceLibs + (isTopLevelTarget ? moduleMapTargets : [])
    }

    private static func makeSubspecTargets(parentSpecs: [PodSpec], spec: PodSpec) -> [BazelTarget] {
        let bundles: [BazelTarget] = bundleLibraries(withPodSpec: spec)
        let libraries = vendoredLibraries(withPodspec: spec)
        let frameworks = vendoredFrameworks(withPodspec: spec)

        let extraDeps: [BazelTarget] = (
                (libraries as [BazelTarget]) +
                        (frameworks as [BazelTarget]))
        let sourceLibs = makeSourceLibs(parentSpecs: parentSpecs, spec: spec,
                extraDeps: extraDeps)

        let subspecTargets = spec.subspecs.flatMap {
            makeSubspecTargets(parentSpecs: parentSpecs + [spec], spec: $0)
        }

        return bundles + sourceLibs + libraries + frameworks + subspecTargets
    }

    public static func makeConvertables(
            fromPodspec podSpec: PodSpec,
            buildOptions: BuildOptions = BasicBuildOptions.empty
    ) -> [SkylarkConvertible] {
        let subspecTargets: [BazelTarget] = podSpec.subspecs.flatMap {
            makeSubspecTargets(parentSpecs: [podSpec], spec: $0)
        }

        let defaultSubspecs = Set(podSpec.defaultSubspecs)

        // Note: we use `ObjcLibrary` here to get the name only.
        // Note: We don't currently support having the default being a nested subspec. This also doesn't do anything
        // with subspecs' default subspecs (for nested subspecs).
        let filteredSpecs = podSpec.subspecs
            .filter { defaultSubspecs.contains($0.name) }
            .map { ObjcLibrary(parentSpecs: [podSpec], spec: $0, extraDeps: []).name }
            .reduce(Set()) { result, name in result.union([name]) }

        let defaultSubspecTargets = subspecTargets.reduce([]) { result, target in
            return result + (filteredSpecs.contains(target.name) ? [target] : [])
        }

        let extraDeps = vendoredFrameworks(withPodspec: podSpec) +
            vendoredLibraries(withPodspec: podSpec)

        let allRootDeps = ((defaultSubspecTargets.isEmpty ? subspecTargets :
                    defaultSubspecTargets) + extraDeps)
            .filter { !($0 is AppleResourceBundle || $0 is AppleBundleImport) }

        let sourceLibs = makeSourceLibs(parentSpecs: [], spec: podSpec, extraDeps:
                allRootDeps)

        var output: [BazelTarget] = sourceLibs + subspecTargets +
            bundleLibraries(withPodSpec: podSpec) + extraDeps

        output = UserConfigurableTransform.transform(convertibles: output,
                                                     options: buildOptions,
                                                     podSpec: podSpec)
        output = RedundantCompiledSourceTransform.transform(convertibles: output,
                                                            options: buildOptions,
                                                            podSpec: podSpec)
        output = InsertAcknowledgementsTransform.transform(convertibles: output,
                                                           options: buildOptions,
                                                           podSpec: podSpec)
        output = EmptyDepPruneTransform.transform(convertibles: output,
                                                           options: buildOptions,
                                                           podSpec: podSpec)
        return output
    }
}
