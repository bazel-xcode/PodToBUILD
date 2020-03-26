//
//  BazelConstants.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//
import Foundation

public struct BazelConstants {
    public static let buildFilePath = "BUILD.bazel"

    /// Note: this is a factory, because we change directories. URL ends up
    /// caching paths relative to the CWD.
    public static func buildFileURL() -> URL {
        return URL(fileURLWithPath: buildFilePath)
    }
}
