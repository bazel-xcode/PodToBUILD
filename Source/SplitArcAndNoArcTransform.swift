//
//  SplitArcAndNoArcTransform.swift
//  PodSpecToBUILD
//
//  Created by Brandon Kase on 5/12/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

enum ValidArcFileExtension: String {
    case objC = "m"
    case objCPP = "mm"
}

/// Cocoapods tells us if we have files that require arc
/// Bazel needs us to partition the files so we don't get duplicate symbols
struct SplitArcAndNoArcTransform : SkylarkConvertibleTransform {
    private static func fixIncomplete(pattern: String) -> [String] {
        // a little hacky, but this logic works for FBSDKCoreKit, the one pod we depend on that needs array requires
        if pattern.hasSuffix("**") {
            return ["/*.m", "/*.mm"].map{ pattern + $0 }
        } else if pattern.hasSuffix("*") {
            return [".m", ".mm"].map{ pattern + $0 }
        } else {
            return [pattern]
        }
    }
    
    private static func arcifySourceFiles(lib: ObjcLibrary) -> (/*srcs: */GlobNode) -> GlobNode {
        return { srcs in
            let needArcPatterns: AttrSet<Set<String>> = lib.requiresArc.fold(
                left: { $0 ? srcs.include : AttrSet.empty },
                right: { AttrSet(basic: Set($0.flatMap(fixIncomplete))) }
            )
	        return GlobNode(
	            include: needArcPatterns,
	            exclude: srcs.exclude)
        }
    }
    
    private static func noArcifyNonArcSrcs(oldLib: ObjcLibrary) -> (/*nonArcSrcs: */GlobNode, /*newLib: */ObjcLibrary) -> GlobNode {
        return { _, newLib in
            let noNeedArcPatterns: AttrSet<Set<String>> = oldLib.requiresArc.fold(
                left: { $0 ? AttrSet.empty : oldLib.sourceFiles.include },
                right: { _ in oldLib.sourceFiles.include }
            )
	        return GlobNode(
	            include: noNeedArcPatterns, // if we didnt required arc, then take all the old files
                // exclude the files included earlier in addition to the other excludes so that we have a partition
	            exclude: newLib.sourceFiles.include <> oldLib.sourceFiles.exclude)

        }
    }


    private static func appendNoArcCFiles(srcs: GlobNode, lib: ObjcLibrary) -> GlobNode {
        let (_, invalid) = lib.nonArcSrcs.partition {
            ValidArcFileExtension(rawValue: URL(fileURLWithPath: $0).pathExtension) != nil
        }

        return GlobNode(include: invalid.include, exclude: AttrSet.empty) <> srcs
    }


    private static func deleteNoArcCFiles(srcs: GlobNode, lib: ObjcLibrary) -> GlobNode {
        let (valid, _) = lib.nonArcSrcs.partition {
            ValidArcFileExtension(rawValue: URL(fileURLWithPath: $0).pathExtension) != nil
        }

        return valid
    }

    static func transform(convertibles: [SkylarkConvertible], options: BuildOptions) -> [SkylarkConvertible] {
        return convertibles.map{ convertible in
            (convertible as? ObjcLibrary).map{ objcLibrary in
                objcLibrary |>
                    (ObjcLibrary.lens.sourceFiles %~ arcifySourceFiles(lib: objcLibrary)) |>
	                (ObjcLibrary.lens.nonArcSrcs %~~ noArcifyNonArcSrcs(oldLib: objcLibrary)) |>
                    (ObjcLibrary.lens.sourceFiles %~~ appendNoArcCFiles) |>
                    (ObjcLibrary.lens.nonArcSrcs %~~ deleteNoArcCFiles)
            } ?? convertible
        }
    }
}
