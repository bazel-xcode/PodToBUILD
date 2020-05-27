//
//  Alias.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 3/25/2020.
//  Copyright © 2020 Pinterest Inc. All rights reserved.

/// This represents an alias in Bazel
/// https://docs.bazel.build/versions/master/be/general.html#alias
public struct Alias : BazelTarget {
    public let name: String
    let actual: String

    public init(name: String, actual: String) {
        self.name = name
        self.actual = actual
    }

    public var acknowledged: Bool {
        return false
    }

    public func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "alias",
            arguments: [
                .named(name: "name", value: bazelLabel(fromString: name).toSkylark()),
                .named(name: "actual", value: actual.toSkylark()),
                ])
    }
}

