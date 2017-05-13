//
//  SplitArcAndNoArcTransform.swift
//  PodSpecToBUILD
//
//  Created by Brandon Kase on 5/12/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

/// Cocoapods tells us if we have files that require arc
/// Bazel needs us to partition the files so we don't get duplicate symbols
struct SplitArcAndNoArcTransform : SkylarkConvertibleTransform {
    private static func arcifySourceFiles(lib: ObjcLibrary) -> (/*srcs: */GlobNode) -> GlobNode {
        return { srcs in
	        let needArcPatterns = lib.requiresArc ? srcs.include : AttrSet.empty
	        return GlobNode(
	            include: needArcPatterns,
	            exclude: srcs.exclude)
        }
    }
    
    private static func noArcifyNonArcSrcs(oldLib: ObjcLibrary) -> (/*nonArcSrcs: */GlobNode, /*newLib: */ObjcLibrary) -> GlobNode {
        return { nonArcSrcs, newLib in
	        let needArcPatterns = oldLib.requiresArc ? AttrSet.empty : oldLib.sourceFiles.include
	        return GlobNode(
	            include: needArcPatterns, // if we required arc, then take all the old files
                // exclude the files included earlier in addition to the other excludes so that we have a partition
	            exclude: newLib.sourceFiles.include <> oldLib.sourceFiles.exclude)
        }
    }
    
    static func transform(convertibles: [SkylarkConvertible], options: BuildOptions) -> [SkylarkConvertible] {
        return convertibles.map{ convertible in
            (convertible as? ObjcLibrary).map{ objcLibrary in
                objcLibrary |>
                    (ObjcLibrary.lens.sourceFiles %~ arcifySourceFiles(lib: objcLibrary)) |>
	                (ObjcLibrary.lens.nonArcSrcs %~~ noArcifyNonArcSrcs(oldLib: objcLibrary))
            } ?? convertible
        }
    }
}
