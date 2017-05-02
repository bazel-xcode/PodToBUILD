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
    
    private static func bundleLibraries(withPodSpec spec: PodSpec) -> [ObjcBundleLibrary] {
        return spec.resourceBundles.map { k, v in
            ObjcBundleLibrary(name: "\(spec.name)_\(k)", resources: v)
        }
    }

    public static func makeConvertables(fromPodspec podSpec: PodSpec, buildOptions: BuildOptions = EmptyBuildOptions()) -> [SkylarkConvertible] {
        let subspecTargets: [BazelTarget] = podSpec.subspecs.flatMap { spec in
            (bundleLibraries(withPodSpec: podSpec) as [BazelTarget]) +
	            ([ObjcLibrary(rootName: podSpec.name, spec: spec) as BazelTarget])
        }
        
        let rootLib = ObjcLibrary(rootName: podSpec.name,
                                spec: podSpec,
                                extraDeps: subspecTargets.map{ $0.name })
        
        // We don't care about the values here
        // So we just lens to an arbitrary monoid that we can <>
        // Trivial has no information, we just care about whether or not it's nil
        let trivialized: Lens<PodSpecRepresentable, Trivial?> = ReadonlyLens(const(.some(Trivial())))
        
        // Just assume ios for now, we can figure out the proper commands later
        let configs: [SkylarkConvertible] = (
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.ios >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.ios.rawValue,
                                           values: ["cpu": "powerpc1"]) ])) <>
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.osx >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.osx.rawValue,
						                   values: ["cpu": "powerpc2"]) ])) <>
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.tvos >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.tvos.rawValue,
                                           values: ["cpu": "powerpc3"]) ])) <>
            (podSpec ^*
                PodSpec.lens.liftOntoSubspecs(PodSpec.lens.watchos >•> trivialized))
                .map(const([ ConfigSetting(name: SelectCase.watchos.rawValue,
                                           values: ["cpu": "powerpc4"]) ]))
        ) ?? []
        
        var output: [SkylarkConvertible] = configs + [rootLib] + subspecTargets
        // Execute transforms manually
        // Don't use unneeded abstractions to make a few function calls
        output = UserConfigurableTransform.transform(convertibles: output, options: buildOptions)
        output = RedundantCompiledSourceTransform.transform(convertibles: output, options: buildOptions)
        return output
    }
}
