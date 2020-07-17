//
//  InsertAcknowledgementsTransform.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 05/21/18.
//  Copyright © 2020 Pinterest Inc. All rights reserved.
//

import Foundation

/// Insert Acknowledgment Nodes for all of the `acknowledgeable` Bazel Targets.
struct InsertAcknowledgementsTransform {
    static func transform(convertibles: [BazelTarget], options _: BuildOptions,
                          podSpec: PodSpec) -> [BazelTarget] {
        return convertibles.map { target -> [BazelTarget] in
            guard target.acknowledged else {
                return [target]
            }

            let deps = target.acknowledgedDeps?.sorted(by: (<))
                ?? [String]()
            let externalDeps = deps.filter { $0.hasPrefix("//") }
            let acknowledgement = AcknowledgmentNode(name: target.name + "_acknowledgement",
                license: podSpec.license,
                deps: externalDeps)
            var arr: [BazelTarget] =  []
            arr.append(target)
            arr.append(acknowledgement)
            return arr
        }.flatMap { $0 }
    }
}
