//
//  UmbrellaHeader.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 7/31/20.
//  Copyright © 2020 Pinterest Inc. All rights reserved.
//
public struct UmbrellaHeader: BazelTarget {
    public let name: String // A unique name for this rule.
    public let headers: [String]
    
    public init(name: String, headers: [String]) {
        self.name = name
        self.headers = headers
    }

    public var acknowledged: Bool {
        return false
    }

    public func toSkylark() -> SkylarkNode {
        var args: [SkylarkFunctionArgument] = [
            .named(name: "name", value: name.toSkylark()),
            .named(name: "hdrs", value: headers.toSkylark()),
        ]
        return SkylarkNode.functionCall(
                name: "umbrella_header",
                arguments: args
         )
    }
}

