//
//  Skylark.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

enum SkylarkNode {
    // A string in Skylark.
    // @note The string value is enclosed within ""
    case string(value: String)

    // A multiline string in Skylark.
    // @note The string value enclosed within """ """
    case multiLineString(value: String)

    // A list of any Skylark Types
    case list(value: [SkylarkNode])

    // A function call.
    // Arguments may be either named or basic
    case functionCall(name: String, arguments: [SkylarkFunctionArgument])

    // Arbitrary skylark code.
    // This code is escaped and compiled directly as specifed in the string.
    // Use this for code that needs to be evaluated.
    case skylark(value: String)
}

enum SkylarkFunctionArgument {
    case basic(value: SkylarkNode)
    case named(name: String, value: SkylarkNode)
}

// MARK: - SkylarkCompiler

struct SkylarkCompiler {
    let nodes: [SkylarkNode]
    let indent: Int
    private let whitespace: String

    init(_ nodes: [SkylarkNode], indent: Int = 0) {
        self.nodes = nodes
        self.indent = indent
        whitespace = SkylarkCompiler.white(indent: indent)
    }

    func run() -> String {
        var buildFile = ""
        for skylark in nodes {
            buildFile += "\(compile(skylark))\n"
        }
        return buildFile
    }

    func compile(_ type: SkylarkNode) -> String {
        var buildFile = ""
        switch type {
        case let .string(value):
            return "\"\(value)\""
        case let .multiLineString(value):
            return "\"\"\"\(value)\"\"\""
        case let .functionCall(call, arguments):
            let compiler = SkylarkCompiler([type], indent: indent + 2)
            return compiler.compile(call: call, arguments: arguments)
        case let .skylark(value):
            return value
        case let .list(value):
            buildFile += "[\n"
            for (idx, type) in value.enumerated() {
                let comma = idx == value.count - 1 ? "" : ",\n"
                buildFile += "\(SkylarkCompiler.white(indent: indent + 2))\(compile(type))\(comma)"
            }
            buildFile += "\n\(whitespace)]"
        }
        return buildFile
    }

    // MARK: - Private

    private func compile(call: String, arguments: [SkylarkFunctionArgument]) -> String {
        var buildFile = ""
        buildFile += "\(call)(\n"
        for (idx, argument) in arguments.enumerated() {
            let comma = idx == arguments.count - 1 ? "" : ","
            switch argument {
            case let .named(name, argValue):
                buildFile += "\(whitespace)\(name) = \(compile(argValue))\(comma)\n"
            case let .basic(argValue):
                buildFile += "\(whitespace)\(compile(argValue))\(comma)\n"
            }
        }
        buildFile += "\(whitespace))"
        return buildFile
    }

    private static func white(indent: Int) -> String {
        if indent == 0 {
            return ""
        }

        var white = ""
        for _ in 1 ... indent {
            white += " "
        }
        return white
    }
}
