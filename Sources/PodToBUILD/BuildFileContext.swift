//
//  BuildFileContext.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 10/17/2018.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

fileprivate var shared: BuildFileContext? = nil

/// BuildFileContext
/// Usage:
/// During Skylark generation of a BuildFile the BuildFile context
/// exposes all BazelTargets inside of the BuildFile.
struct BuildFileContext {
    private let bazelTargetByName: [String: BazelTarget]

    init(convertibles: [SkylarkConvertible]) {
        var bazelTargetByName: [String: BazelTarget] = [:]
        convertibles.forEach { convertible in
            guard let target = convertible as? BazelTarget else {
                return
            }
            bazelTargetByName[target.name] = target
        }
        self.bazelTargetByName = bazelTargetByName
    }

    public func getBazelTarget(name: String) -> BazelTarget? {
        return bazelTargetByName[name]
    }

    public static func set(_ context: BuildFileContext?) {
        shared = context
    }

    public static func get() -> BuildFileContext? {
        return shared
    }
}


