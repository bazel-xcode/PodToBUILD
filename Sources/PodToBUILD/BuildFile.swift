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
    let releaseConfig = SkylarkNode.functionCall(name: "config_setting",
                                                 arguments: [
                                                     .named(name: "name", value: .string("release")),
                                                     .named(name: "values",
                                                            value:
                                                            [
                                                            "compilation_mode": "opt"
                                                            ].toSkylark()
                                                     ),
    ])

    return .lines([.lines(comment), releaseConfig])
}

public func makeLoadNodes(forConvertibles skylarkConvertibles: [SkylarkConvertible]) -> SkylarkNode {
    let hasSwift = skylarkConvertibles.first(where: { $0 is SwiftLibrary }) != nil
    let hasAppleBundleImport = skylarkConvertibles.first(where: { $0 is AppleBundleImport }) != nil
    let hasAppleResourceBundle = skylarkConvertibles.first(where: { $0 is AppleResourceBundle }) != nil
    let hasAppleStaticFrameworkImport = skylarkConvertibles.first(where: { $0 is AppleStaticFrameworkImport }) != nil
    return .lines( [
        hasSwift ?  SkylarkNode.skylark("load('@build_bazel_rules_swift//swift:swift.bzl', 'swift_library')") : nil,
        hasAppleBundleImport ?  SkylarkNode.skylark("load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_bundle_import')") : nil,
        hasAppleResourceBundle ?  SkylarkNode.skylark("load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_resource_bundle')") : nil,
        hasAppleStaticFrameworkImport ?  SkylarkNode.skylark("load('@build_bazel_rules_apple//apple:apple.bzl', 'apple_static_framework_import')") : nil,
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
            .basic(.string("pch_with_name_hint")),
            .basic(.string("acknowledged_target")),
            .basic(.string("gen_module_map")),
            .basic(.string("gen_includes")),
            .basic(.string("headermap"))]),
        makeConfigSettingNodes(),
    ]
    return .lines(lineNodes)
}

/// Acknowledgment node exposes an acknowledgment fragment including all of
/// the `deps` acknowledgment fragments.
public struct AcknowledgmentNode: SkylarkConvertible {
    let name: String
    let license: PodSpecLicense
    let deps: [String]

    public func toSkylark() -> SkylarkNode {
        let nodeName = bazelLabel(fromString: name + "_acknowledgement").toSkylark()
        let options = GetBuildOptions()
        let value: String
        let podSupportBuildableDir = String(PodSupportBuidableDir.utf8.dropLast())!
        if options.path == "." {
            value = (getRulePrefix(name: options.podName) +
                        podSupportBuildableDir + ":acknowledgement_fragment")
        } else {
            // TODO: This will not work with external. Consider moving this file to
            // pod_support instead.
            value = "//\(options.path)/\(podSupportBuildableDir):acknowledgement_fragment"
        }
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

/// Insert Acknowledgment Nodes for all of the `acknowledgeable` Bazel Targets.
struct InsertAcknowledgementsTransform: SkylarkConvertibleTransform {
    static func transform(convertibles: [SkylarkConvertible], options _: BuildOptions, podSpec: PodSpec) -> [SkylarkConvertible] {
        return convertibles.map { convertible in
            (convertible as? BazelTarget).map { target in
                guard target.acknowledged else {
                    return [target]
                }

                let deps = target.acknowledgedDeps?.sorted(by: (<))
                    ?? [String]()
                let externalDeps = deps.filter { $0.hasPrefix("//") }
                let acknowledgement = AcknowledgmentNode(name: target.name,
                                                         license: podSpec.license,
                                                         deps: externalDeps)
                return [target, acknowledgement]
            } ?? [convertible]
        }.flatMap { $0 }
    }
}

public struct PodBuildFile: SkylarkConvertible {
    /// Skylark Convertibles excluding prefix nodes.
    /// @note Use toSkylark() to generate the actual BUILD file
    public let skylarkConvertibles: [SkylarkConvertible]

    /// When there is a podspec adjacent to another, we need to concat
    /// the "child" BUILD file into the parents
    public let assimilate: Bool

    public static func shouldAssimilate(buildOptions: BuildOptions) -> Bool {
        return buildOptions.path != "." &&
            FileManager.default.fileExists(atPath: BazelConstants.buildFilePath)
    }

    /// Return the skylark representation of the entire BUILD file
    public func toSkylark() -> SkylarkNode {
        BuildFileContext.set(BuildFileContext(convertibles: skylarkConvertibles))
        let convertibleNodes: [SkylarkNode] = skylarkConvertibles.compactMap { $0.toSkylark() }
        BuildFileContext.set(nil)

        // If we have to assimilate this into another build file then don't
        // write prefix nodes. This is not 100% pefect, as some other algorithms
        // require all contents of the build file. This is an intrim solution.
        let prefixNodes = assimilate  ? SkylarkNode.empty : makePrefixNodes()
        return .lines([
            makeLoadNodes(forConvertibles: skylarkConvertibles),
            prefixNodes]
            + convertibleNodes)
    }

    public static func with(podSpec: PodSpec, buildOptions: BuildOptions = BasicBuildOptions.empty) -> PodBuildFile {
        sharedBuildOptions = buildOptions
        let libs = PodBuildFile.makeConvertables(fromPodspec: podSpec, buildOptions: buildOptions)
        return PodBuildFile(skylarkConvertibles: libs, assimilate:
            PodBuildFile.shouldAssimilate(buildOptions: buildOptions))
    }

    private static func bundleLibraries(withPodSpec spec: PodSpec) -> [BazelTarget] {
        let resourceBundleAttrSet: AttrSet<[String: [String]]> = spec ^* liftToAttr(PodSpec.lens.resourceBundles)

        // See if the Podspec specifies a prebuilt .bundle file
        let bundleResources = (spec ^* liftToAttr(PodSpec.lens.resources)).map { (strArr: [String]) -> [String] in
            strArr.filter({ (str: String) -> Bool in
                str.hasSuffix(".bundle")
            })
        }

        let bundleTargets = bundleResources.map { (strArr: [String]) -> [BazelTarget] in
            strArr.map { (bundlePath: String) -> BazelTarget in
                let bundleName = AppleBundleImport.extractBundleName(fromPath: bundlePath)
                let name = "\(spec.moduleName ?? spec.name)_Bundle_\(bundleName)"
                let bundleImports = AttrSet<[String]>(basic: ["\(bundlePath)/**"])
                return AppleBundleImport(name: name, bundleImports: bundleImports)
            }
        }

        let resourceBundles = (AttrSet<[String: [String]]>
            .sequence(attrSet: resourceBundleAttrSet)
            .map { k, v -> BazelTarget in
                let name = "\(spec.moduleName ?? spec.name)_Bundle_\(k)"
                return AppleResourceBundle(name: name, resources: v)
            })

        return (resourceBundles + (bundleTargets.basic ?? [])).sorted { $0.name < $1.name }
    }

    private static func vendoredFrameworks(withPodspec spec: PodSpec) -> [BazelTarget] {
        let frameworks = spec ^* liftToAttr(PodSpec.lens.vendoredFrameworks)
        return frameworks.isEmpty ? [] : [AppleStaticFrameworkImport(name: "\(spec.moduleName ?? spec.name)_VendoredFrameworks", frameworkImports: frameworks)]
    }

    private static func vendoredLibraries(withPodspec spec: PodSpec) -> [BazelTarget] {
        let libraries = spec ^* liftToAttr(PodSpec.lens.vendoredLibraries)
        return libraries.isEmpty ? [] : [ObjcImport(name: "\(spec.moduleName ?? spec.name)_VendoredLibraries", archives: libraries)]
    }

    static func getSourceTypes(fromPodspec spec: PodSpec) ->
        Set<BazelSourceLibType> {
        let sources = spec ^* liftToAttr(PodSpec.lens.sourceFiles)

        let objcLike = extractFiles(fromPattern: sources, includingFileTypes:
                ObjcLikeFileTypes)
        var result: Set<BazelSourceLibType> = Set()
        if !objcLike.isEmpty {
            result.insert(.objc)
        }

        let cppLike = extractFiles(fromPattern: sources, includingFileTypes:
                CppLikeFileTypes)
        if !cppLike.isEmpty {
            result.insert(.cpp)
        }

        let swiftLike = extractFiles(fromPattern: sources, includingFileTypes:
                SwiftLikeFileTypes)
        if !swiftLike.isEmpty {
            // Warning: `swift_library` chokes if we give it empty source files
            // at link time. Consider fixing that. Otherwise, we can hit the
            // file system for unbounded globs here and determine deps based on
            // those globs, or continue to emit the dep and determine if it
            // should be a dep in Bazel. The latter limiting based on the
            // current design.
            result.insert(.swift)
        }
        return result
    }

    /// Construct source libs
    /// Depending on the source files and other factors, we'll return different
    /// kinds of rules for a PodSpec and corresponding SubSpecs
    static func makeSourceLibs(rootSpec podSpec: PodSpec?, spec: PodSpec,
            extraDeps: [BazelTarget]) -> [BazelTarget] {
        var sourceLibs: [BazelTarget] = []
        // Split libs based on the sources involved.
        let sourceTypes = getSourceTypes(fromPodspec: spec)
        if sourceTypes.count == 0 {
            sourceLibs.append(ObjcLibrary(rootSpec: podSpec, spec: spec,
                        extraDeps: extraDeps.map { $0.name }, sourceType:
                        .objc))
        } else if sourceTypes.count == 1 {
            if sourceTypes.first == .swift {
                sourceLibs.append(SwiftLibrary(rootSpec: podSpec, spec: spec,
                            extraDeps: extraDeps.map { $0.name }))
                fputs("WARNING: swift support is currently WIP", __stderrp)
            } else {
                sourceLibs.append(ObjcLibrary(rootSpec: podSpec, spec: spec,
                            extraDeps: extraDeps.map { $0.name },
                            sourceType: sourceTypes.first!))
            }
        } else {
            // Split out Cpp and Swift libraries into seperate libraries
            // The Objective-C libarary is the parent library ATM - is that
            // applicable for all cases?
            var splitDeps: [BazelTarget] = []

            if sourceTypes.contains(.cpp) {
                let cppLib = ObjcLibrary(rootSpec: podSpec, spec: spec,
                        extraDeps: extraDeps.map { $0.name },
                        isSplitDep: true, sourceType: .cpp)
                splitDeps.append(cppLib)
                sourceLibs.append(cppLib)
            }

            if sourceTypes.contains(.swift) {
                // Append a swift library.
                let swiftLib = SwiftLibrary(rootSpec: podSpec, spec: spec,
                        extraDeps: extraDeps.map { $0.name },
                        isSplitDep: true)
                splitDeps.append(swiftLib)
                sourceLibs.append(swiftLib)

                fputs("WARNING: swift support is currently WIP", __stderrp)
            }

            // In this case, the root lib is Objc
            let rootLib = ObjcLibrary(rootSpec: podSpec, spec: spec,
                    extraDeps: (extraDeps + splitDeps).map { $0.name })
            sourceLibs.append(rootLib)
        }
        return sourceLibs
    }

    public static func makeConvertables(fromPodspec podSpec: PodSpec,
            buildOptions: BuildOptions = BasicBuildOptions.empty) ->
        [SkylarkConvertible] {
        let subspecTargets: [BazelTarget] = podSpec.subspecs.reduce([]) {
            accum, spec in
            let bundles: [BazelTarget] = bundleLibraries(withPodSpec: spec)
            let libraries = vendoredLibraries(withPodspec: spec)
            let frameworks = vendoredFrameworks(withPodspec: spec)

            let extraDeps: [BazelTarget] = (
                    (libraries as [BazelTarget]) +
                    (frameworks as [BazelTarget]))
            let sourceLibs = makeSourceLibs(rootSpec: podSpec, spec: spec,
                    extraDeps: extraDeps)
            return accum + bundles + sourceLibs + libraries +
                frameworks
        }

        let defaultSubspecs = Set(podSpec.defaultSubspecs)

        // Note: we use `ObjcLibrary` here to get the name only.
        // TODO: how does filtering impact dep splitting?
        let filteredSpecs = podSpec.subspecs
            .filter { defaultSubspecs.contains($0.name) }
            .map { ObjcLibrary(rootSpec: podSpec, spec: $0, extraDeps: []).name }
            .reduce(Set()) { result, name in result.union([name]) }

        let defaultSubspecTargets = subspecTargets.reduce([]) { result, target in
            return result + (filteredSpecs.contains(target.name) ? [target] : [])
        }

        let extraDeps = vendoredFrameworks(withPodspec: podSpec) +
            vendoredLibraries(withPodspec: podSpec)

        let allRootDeps = ((defaultSubspecTargets.isEmpty ? subspecTargets :
                    defaultSubspecTargets) + extraDeps)
        let sourceLibs = makeSourceLibs(rootSpec: nil, spec: podSpec, extraDeps:
                allRootDeps)

        // We don't care about the values here
        // So we just lens to an arbitrary monoid that we can <+>
        // Trivial has no information, we just care about whether or not it's nil
        let trivialized: Lens<PodSpecRepresentable, Trivial?> = ReadonlyLens(const(.some(Trivial())))

        // Just assume ios for now, we can figure out the proper commands later
        // We should remove this altogether, it doesn't do anything.
        let configs: [BazelTarget] = (
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.ios >•> trivialized))
                .map(const([ConfigSetting(name: SelectCase.ios.rawValue,
                                          values: ["cpu": "powerpc1"])])) <+>
                (podSpec ^*
                    PodSpec.lens.liftOntoSubspecs(PodSpec.lens.osx >•> trivialized))
                .map(const([ConfigSetting(name: SelectCase.osx.rawValue,
                                          values: ["cpu": "powerpc2"])])) <+>
                (podSpec ^*
                    PodSpec.lens.liftOntoSubspecs(PodSpec.lens.tvos >•> trivialized))
                .map(const([ConfigSetting(name: SelectCase.tvos.rawValue,
                                          values: ["cpu": "powerpc3"])])) <+>
                (podSpec ^*
                    PodSpec.lens.liftOntoSubspecs(PodSpec.lens.watchos >•> trivialized))
                .map(const([ConfigSetting(name: SelectCase.watchos.rawValue,
                                          values: ["cpu": "powerpc4"])]))
        ) ?? []

        var output: [SkylarkConvertible] = configs + sourceLibs + subspecTargets +
            bundleLibraries(withPodSpec: podSpec) + extraDeps

        // Execute transforms manually
        // Don't use unneeded abstractions to make a few function calls
        // (bkase) but this is isomorphic to `BuildOptions -> Endo<SkylarkConvertible>` which means we *could* make a monoid out of it http://swift.sandbox.bluemix.net/#/repl/59090e9f9def327b2a45b255
        output = UserConfigurableTransform.transform(convertibles: output,
                                                     options: buildOptions,
                                                     podSpec: podSpec)
        output = RedundantCompiledSourceTransform.transform(convertibles: output,
                                                            options: buildOptions,
                                                            podSpec: podSpec)
        output = SplitArcAndNoArcTransform.transform(convertibles: output,
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
