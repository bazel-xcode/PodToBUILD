//
//  BazelTarget.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 10/17/2018.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

/// Law: Names must be valid bazel names; see the spec
protocol BazelTarget: SkylarkConvertible {
    var name: String { get }
    var acknowledgedDeps: [String]? { get }
    var acknowledged: Bool { get }
}

extension BazelTarget {
    var acknowledgedDeps: [String]? {
        return nil
    }

    var acknowledged: Bool {
        return false
    }
}

