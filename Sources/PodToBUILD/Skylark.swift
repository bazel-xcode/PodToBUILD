//
//  Skylark.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

public indirect enum SkylarkNode {
    /// A integer in Skylark.
    case int(Int)

    /// A string in Skylark.
    /// @note The string value is enclosed within ""
    case string(String)

    /// A multiline string in Skylark.
    /// @note The string value enclosed within """ """
    case multiLineString(String)

    /// A list of any Skylark Types
    case list([SkylarkNode])

    /// A function call.
    /// Arguments may be either named or basic
    case functionCall(name: String, arguments: [SkylarkFunctionArgument])

    /// Arbitrary skylark code.
    /// This code is escaped and compiled directly as specifed in the string.
    /// Use this for code that needs to be evaluated.
    case skylark(String)

    /// A skylark dict
    case dict([String: SkylarkNode])

    /// An expression with a lhs and a rhs separated by an op
    case expr(lhs: SkylarkNode, op: String, rhs: SkylarkNode)

    /// Lines are a bunch of nodes that we will render as separate lines
    case lines([SkylarkNode])

    /// Flatten nested lines to a single array of lines
    func canonicalize() -> SkylarkNode {
        // at the inner layer we just strip the .lines
        func helper(inner: SkylarkNode) -> [SkylarkNode] {
            switch inner {
            case let .lines(nodes): return nodes
            case let other: return [other]
            }
        }

        // and at the top level we keep the .lines wrapper
        switch self {
        case let .lines(nodes): return .lines(nodes.flatMap(helper))
        case let other: return other
        }
    }
}

extension SkylarkNode: Monoid, EmptyAwareness {
    public static var empty: SkylarkNode { return .list([]) }

    // TODO(bkase): Annotate AttrSet with monoidal public struct wrapper to get around this hack
    /// WARNING: This doesn't obey the laws :(.
    public static func<>(lhs: SkylarkNode, rhs: SkylarkNode) -> SkylarkNode {
        return lhs .+. rhs
    }

    public var isEmpty: Bool {
        switch self {
        case let .list(xs): return xs.isEmpty
        default: return false
        }
    }
}

// because it must be done
infix operator .+.: AdditionPrecedence
func .+.(lhs: SkylarkNode, rhs: SkylarkNode) -> SkylarkNode {
    switch (lhs, rhs) {
    case (.list(let l), .list(let r)): return .list(l + r)
    case (_, .list(let v)) where v.isEmpty: return lhs
    case (.list(let v), _) where v.isEmpty: return rhs
    default: return .expr(lhs: lhs, op: "+", rhs: rhs)
    }
}

infix operator .=.: AdditionPrecedence
func .=.(lhs: SkylarkNode, rhs: SkylarkNode) -> SkylarkNode {
    return .expr(lhs: lhs, op: "=", rhs: rhs)
}

public indirect enum SkylarkFunctionArgument {
    case basic(SkylarkNode)
    case named(name: String, value: SkylarkNode)
}


// MARK: - SkylarkCompiler

public struct SkylarkCompiler {
    let root: SkylarkNode
    let indent: Int
    private let whitespace: String

    public init(_ lines: [SkylarkNode]) {
        self.init(.lines(lines))
    }

    public init(_ root: SkylarkNode, indent: Int = 0) {
        self.root = root.canonicalize()
        self.indent = indent
        whitespace = SkylarkCompiler.white(indent: indent)
    }

    public func run() -> String {
        return compile(root)
    }

    private func compile(_ node: SkylarkNode) -> String {
        switch node {
        case let .int(value):
            return "\(value)"
        case let .string(value):
            return "\"\(value)\""
        case let .multiLineString(value):
            return "\"\"\"\(value)\"\"\""
        case let .functionCall(call, arguments):
            let compiler = SkylarkCompiler(node, indent: indent + 2)
            return compiler.compile(call: call, arguments: arguments, closeParenWhitespace: whitespace)
        case let .skylark(value):
            return value
        case let .list(value):
            guard !value.isEmpty else { return "[]" }
            return "[\n" + value.map { node in
                "\(SkylarkCompiler.white(indent: indent + 2))\(compile(node))"
            }.joined(separator: ",\n") + "\n\(whitespace)]"
        case let .expr(lhs, op, rhs):
            return compile(lhs) + " \(op) " + compile(rhs)
        case let .dict(dict):
            guard !dict.isEmpty else { return "{}" }
            // Stabilize dict keys here. Other inputs are required to be stable.
            let sortedKeys = Array(dict.keys).sorted { $0 < $1 }
            let compiler = SkylarkCompiler(node, indent: indent + 2)
            return "{\n" + sortedKeys.compactMap { key in
                guard let val = dict[key] else { return nil }
                return "\(SkylarkCompiler.white(indent: indent + 2))\(compiler.compile(.string(key))): \(compiler.compile(val))"
            }.joined(separator: ",\n") + "\n\(whitespace)}"
        case let .lines(lines):
            return lines.map(compile).joined(separator: "\n")
        }
    }

    // MARK: - Private

    private func compile(call: String, arguments: [SkylarkFunctionArgument], closeParenWhitespace: String) -> String {
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
        buildFile += "\(closeParenWhitespace))"
        return buildFile
    }

    private static func white(indent: Int) -> String {
        precondition(indent >= 0)

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
