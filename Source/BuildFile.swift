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
}

// Nullability is the root of all evil
public struct EmptyBuildOptions : BuildOptions {
    public let userOptions = [String]()
    public let globalCopts = [String]()
    public let trace: Bool = false

    static let shared = EmptyBuildOptions()
}

public struct PodBuildFile {
    public let skylarkConvertibles: [SkylarkConvertible]
    static let xcconfigTransformer = XCConfigTransformer.defaultTransformer()

    public static func with(podSpec: PodSpec, buildOptions: BuildOptions = EmptyBuildOptions()) -> PodBuildFile {
        let libs = PodBuildFile.makeConvertables(fromPodspec: podSpec, buildOptions: buildOptions)
        return PodBuildFile(skylarkConvertibles: libs)
    }

    private static func bundleLibraries(withPodSpec spec: PodSpec) -> [BazelTarget] {
        let resourceBundleAttrSet: AttrSet<[String: [String]]> = spec ^* liftToAttr(PodSpec.lens.resourceBundles)

//        let resourcesAttrSet = (spec ^* liftToAttr(PodSpec.lens.resources)).map { arr -> [String] in
//            guard let nonOptArr = arr else { return [] }
//            return nonOptArr
//        }
        // Resources specified using the "resources" key in the Podspec.
//        let defaultResources: [BazelTarget] = spec.resources == nil ? [] :  [ObjcBundleLibrary(name: "\(spec.name)_Bundle", resources: resourcesAttrSet)]

        return AttrSet<[String: [String]]>.sequence(attrSet: resourceBundleAttrSet).map { k, v in
            ObjcBundleLibrary(name: "\(spec.name)_Bundle_\(k)", resources: v)
        }
    }

    private static func vendoredFrameworks(withPodspec spec: PodSpec) -> [BazelTarget] {
        let frameworks  = spec ^* liftToAttr(PodSpec.lens.vendoredFrameworks)
        return frameworks.isEmpty ? [] : [ObjcFramework(name: "\(spec.name)_VendoredFrameworks", frameworkImports: frameworks)]
    }

    private static func vendoredLibraries(withPodspec spec: PodSpec) -> [BazelTarget] {
        let libraries  = spec ^* liftToAttr(PodSpec.lens.vendoredLibraries)
        return libraries.isEmpty ? [] : [ObjcImport(name: "\(spec.name)_VendoredLibraries", archives: libraries)]
    }

    public static func makeConvertables(fromPodspec podSpec: PodSpec, buildOptions: BuildOptions = EmptyBuildOptions()) -> [SkylarkConvertible] {
        let subspecTargets: [BazelTarget] = podSpec.subspecs.flatMap { spec in
            (bundleLibraries(withPodSpec: spec) as [BazelTarget]) +
            ([ObjcLibrary(rootSpec: podSpec,
                          spec: spec,
                          extraDeps:((vendoredLibraries(withPodspec: spec) as [BazelTarget]) +
                                     (vendoredFrameworks(withPodspec: spec) as [BazelTarget]))
                                    .map { $0.name } ) as BazelTarget]) +
            vendoredLibraries(withPodspec: spec) +
            vendoredFrameworks(withPodspec: spec)
        }

        let extraDeps = bundleLibraries(withPodSpec: podSpec) + vendoredFrameworks(withPodspec: podSpec) + vendoredLibraries(withPodspec: podSpec)
        let rootLib = ObjcLibrary(spec: podSpec,
                                  extraDeps: (subspecTargets + extraDeps).map{ $0.name })

        // We don't care about the values here
        // So we just lens to an arbitrary monoid that we can <+>
        // Trivial has no information, we just care about whether or not it's nil
        let trivialized: Lens<PodSpecRepresentable, Trivial?> = ReadonlyLens(const(.some(Trivial())))

        // Just assume ios for now, we can figure out the proper commands later
        let configs: [BazelTarget] = (
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.ios >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.ios.rawValue,
                                           values: ["cpu": "powerpc1"]) ])) <+>
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.osx >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.osx.rawValue,
						                   values: ["cpu": "powerpc2"]) ])) <+>
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.tvos >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.tvos.rawValue,
                                           values: ["cpu": "powerpc3"]) ])) <+>
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.watchos >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.watchos.rawValue,
                                           values: ["cpu": "powerpc4"]) ]))
        ) ?? []

        var output: [SkylarkConvertible] = configs + [rootLib as BazelTarget] + subspecTargets + extraDeps
        // Execute transforms manually
        // Don't use unneeded abstractions to make a few function calls
        // (bkase) but this is isomorphic to `BuildOptions -> Endo<SkylarkConvertible>` which means we *could* make a monoid out of it http://swift.sandbox.bluemix.net/#/repl/59090e9f9def327b2a45b255
        output = UserConfigurableTransform.transform(convertibles: output, options: buildOptions)
        output = RedundantCompiledSourceTransform.transform(convertibles: output, options: buildOptions)
        return output
    }
}

