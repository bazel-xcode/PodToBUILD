//
//  SplitArcAndNoArcTransform.swift
//  PodToBUILD
//
//  Created by Brandon Kase on 5/12/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

enum ValidArcFileExtension: String {
    case objC = "m"
    case objCPP = "mm"
}

/// Cocoapods tells us if we have files that require arc
/// Bazel needs us to gpartition the files so we don't get duplicate symbols

/// This looks crazy but it's works???
/// On thelatest FBSDK
/// # This excludes `FBSDKCoreKit/FBSDKCoreKit/Internal_NoARC/` folder, as that folder includes only `no-arc` files.
 //  s.requires_arc = ['FBSDKCoreKit/FBSDKCoreKit/*',
 ///                     'FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*',
 //                     'FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*',
 //                                 'FBSDKCoreKit/FBSDKCoreKit/Basics/**/*',
 //                     'FBSDKCoreKit/FBSDKCoreKit/Internal/**/*']
 //

// $ find Vendor/FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit -type d -depth 1
// Vendor/FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit/Basics
// Vendor/FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit/Internal
// Vendor/FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit/Internal_NoARC
// Vendor/FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit/AppEvents
// Vendor/FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit/AppLink
/// $ ls Vendor/FBSDKCoreKit/FBSDKCoreKit/FBSDKCoreKit/Internal_NoARC/
/// FBSDKDynamicFrameworkLoader.m


struct SplitArcAndNoArcTransform : SkylarkConvertibleTransform {
    static func transform(convertibles: [BazelTarget], options: BuildOptions, podSpec: PodSpec) -> [BazelTarget] {
        return convertibles
    }
}
