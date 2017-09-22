//
//  Pod.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

public protocol BuildOptions {
    var userOptions: [String] { get }
    var globalCopts: [String] { get }
    var trace: Bool { get }
    var podName: String { get }

    // Frontend options

    var enableModules: Bool { get }
    var generateModuleMap: Bool { get }
	// pod_support, everything, none
    var headerVisibility: String { get }
}

// Nullability is the root of all evil
public struct EmptyBuildOptions: BuildOptions {
    public let userOptions = [String]()
    public let globalCopts = [String]()
    public let trace: Bool = false
    public let podName: String = ""

    public let enableModules: Bool = false
    public let generateModuleMap: Bool = false
    public let headerVisibility: String = ""

    public static let shared = EmptyBuildOptions()
}

public struct BasicBuildOptions: BuildOptions {
    public let podName: String
    public let userOptions: [String]
    public let globalCopts: [String]
    public let trace: Bool

    public let enableModules: Bool
    public let generateModuleMap: Bool
    public let headerVisibility: String

    public init(podName: String,
                userOptions: [String],
                globalCopts: [String],
                trace: Bool,
                enableModules: Bool = false,
                generateModuleMap: Bool = false,
                headerVisibility: String = ""
    ) {
        self.podName = podName
        self.userOptions = userOptions
        self.globalCopts = globalCopts
        self.trace = trace
        self.enableModules = enableModules
        self.generateModuleMap = generateModuleMap
        self.headerVisibility = headerVisibility
    }
}

private var sharedBuildOptions: BuildOptions = EmptyBuildOptions.shared

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
        "# https://bazel.build/versions/master/docs/bazel-user-manual.html",
    ].map { SkylarkNode.skylark($0) }
    let releaseConfig = SkylarkNode.functionCall(name: "native.config_setting",
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

// Make Nodes to be inserted at the beginning of skylark output
// public for test purposes
public func makePrefixNodes() -> SkylarkNode {
    return .lines([
        .skylark("load('//:" + PodSupportBuidableDir + "extensions.bzl', 'pch_with_name_hint')"),
        .skylark("load('//:" + PodSupportBuidableDir + "extensions.bzl', 'acknowledged_target')"),
        .skylark("load('//:" + PodSupportBuidableDir + "extensions.bzl', 'gen_module_map')"),
        makeConfigSettingNodes(),
    ])
}

/// Acknowledgment node exposes an acknowledgment fragment including all of
/// the `deps` acknowledgment fragments.
public struct AcknowledgmentNode: SkylarkConvertible {
    let name: String
    let license: PodSpecLicense
    let deps: [String]

    public func toSkylark() -> SkylarkNode {
        let nodeName = ObjcLibrary.bazelLabel(fromString: name + "_acknowledgement").toSkylark()
        let target = SkylarkNode.functionCall(
            name: "acknowledged_target",
            arguments: [
                .named(name: "name", value: nodeName),
                .named(name: "deps", value: deps.map { $0 + "_acknowledgement" }.toSkylark()),
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

                let deps = target.acknowledgedDeps ?? [String]()
                let acknowledgement = AcknowledgmentNode(name: target.name,
                                                         license: podSpec.license,
                                                         deps: deps)
                return [target, acknowledgement]
            } ?? [convertible]
        }.flatMap { $0 }
    }
}

public struct PodBuildFile: SkylarkConvertible {
    /// Skylark Convertibles excluding prefix nodes.
    /// @note Use toSkylark() to generate the actual BUILD file
    public let skylarkConvertibles: [SkylarkConvertible]

    /// Return the skylark representation of the entire BUILD file
    public func toSkylark() -> SkylarkNode {
        let convertibleNodes: [SkylarkNode] = skylarkConvertibles.flatMap { $0.toSkylark() }
        return .lines([makePrefixNodes()] + convertibleNodes)
    }

    public static func with(podSpec: PodSpec, buildOptions: BuildOptions = EmptyBuildOptions.shared) -> PodBuildFile {
        sharedBuildOptions = buildOptions
        let libs = PodBuildFile.makeConvertables(fromPodspec: podSpec, buildOptions: buildOptions)
        return PodBuildFile(skylarkConvertibles: libs)
    }

    private static func bundleLibraries(withPodSpec spec: PodSpec) -> [BazelTarget] {
        let resourceBundleAttrSet: AttrSet<[String: [String]]> = spec ^* liftToAttr(PodSpec.lens.resourceBundles)

        // See if the Podspec specifies a prebuilt .bundle file
        let bundleResources = (spec ^* liftToAttr(PodSpec.lens.resources)).map { (strArr: [String]) -> [String] in
            strArr.filter({ (str: String) -> Bool in
                str.hasSuffix(".bundle")
            })
        }

        // For all prebuilt bundles we found, create an ObjcBundle target. This target differs from ObjCBundleLibrary
        // because it is stricter about keeping the structure of the bundle contents intact.
        let bundleTargets = bundleResources.map { (strArr: [String]) -> [BazelTarget] in
            strArr.map { (bundlePath: String) -> BazelTarget in
                let bundleName = ObjcBundle.extractBundleName(fromPath: bundlePath)
                let name = "\(spec.moduleName ?? spec.name)_Bundle_\(bundleName)"
                let bundleImports = AttrSet<[String]>(basic: ["\(bundlePath)/**"])
                return ObjcBundle(name: name, bundleImports: bundleImports)
            }
        }


        let resourceBundles =   (AttrSet<[String: [String]]>.sequence(attrSet: resourceBundleAttrSet).map { k, v in
            ObjcBundleLibrary(name: "\(spec.moduleName ?? spec.name)_Bundle_\(k)", resources: v) as BazelTarget
        })

        return resourceBundles + (bundleTargets.basic ?? [])
    }

    private static func vendoredFrameworks(withPodspec spec: PodSpec) -> [BazelTarget] {
        let frameworks = spec ^* liftToAttr(PodSpec.lens.vendoredFrameworks)
        return frameworks.isEmpty ? [] : [ObjcFramework(name: "\(spec.moduleName ?? spec.name)_VendoredFrameworks", frameworkImports: frameworks)]
    }

    private static func vendoredLibraries(withPodspec spec: PodSpec) -> [BazelTarget] {
        let libraries = spec ^* liftToAttr(PodSpec.lens.vendoredLibraries)
        return libraries.isEmpty ? [] : [ObjcImport(name: "\(spec.moduleName ?? spec.name)_VendoredLibraries", archives: libraries)]
    }

    public static func makeConvertables(fromPodspec podSpec: PodSpec, buildOptions: BuildOptions = EmptyBuildOptions.shared) -> [SkylarkConvertible] {
        let subspecTargets: [BazelTarget] = podSpec.subspecs.flatMap { spec in
            (bundleLibraries(withPodSpec: spec) as [BazelTarget]) +
                ([ObjcLibrary(rootSpec: podSpec,
                              spec: spec,
                              extraDeps: ((vendoredLibraries(withPodspec: spec) as [BazelTarget]) +
                                  (vendoredFrameworks(withPodspec: spec) as [BazelTarget]))
                                  .map { $0.name }) as BazelTarget]) +
                vendoredLibraries(withPodspec: spec) +
                vendoredFrameworks(withPodspec: spec)
        }

        let defaultSubspecs = Set(podSpec.defaultSubspecs)

        let filteredSpecs = podSpec.subspecs
            .filter { defaultSubspecs.contains($0.name) }
            .map { ObjcLibrary(rootSpec: podSpec, spec: $0, extraDeps: []) }
            .map { $0.name }
            .reduce(Set()) { result, name in result.union([name]) }

        let defaultSubspecTargets = subspecTargets.reduce([]) { result, target in
            return result + (filteredSpecs.contains(target.name) ? [target] : [])
        }

        let extraDeps = bundleLibraries(withPodSpec: podSpec) + vendoredFrameworks(withPodspec: podSpec) + vendoredLibraries(withPodspec: podSpec)
        let rootLib = ObjcLibrary(spec: podSpec,
                                  extraDeps: ((defaultSubspecTargets.isEmpty ? subspecTargets : defaultSubspecTargets) + extraDeps).map { $0.name })

        // We don't care about the values here
        // So we just lens to an arbitrary monoid that we can <+>
        // Trivial has no information, we just care about whether or not it's nil
        let trivialized: Lens<PodSpecRepresentable, Trivial?> = ReadonlyLens(const(.some(Trivial())))

        // Just assume ios for now, we can figure out the proper commands later
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

        var output: [SkylarkConvertible] = configs + [rootLib as BazelTarget] + subspecTargets + extraDeps
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
        return output
    }
}
