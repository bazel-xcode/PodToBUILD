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
    return .expr(lhs: lhs, op: "+", rhs: rhs)
}

infix operator .=.: AdditionPrecedence
func .=.(lhs: SkylarkNode, rhs: SkylarkNode) -> SkylarkNode {
    return .expr(lhs: lhs, op: "=", rhs: rhs)
}

public indirect enum SkylarkFunctionArgument {
    case basic(SkylarkNode)
    case named(name: String, value: SkylarkNode)
}


public struct GlobNode: SkylarkConvertible {
    // Bazel Glob function: glob(include, exclude=[], exclude_directories=1)
    public let include: AttrSet<Set<String>>
    public let exclude: AttrSet<Set<String>>
    public let excludeDirectories: Bool = true
    
    init(include: AttrSet<Set<String>>, exclude: AttrSet<Set<String>>) {
        self.include = include
        self.exclude = exclude
    }

    // Partitions Self into two GlobNodes where the first evaluates to true for the 
    // predicate function.
    func partition(by predicate: @escaping (String) -> Bool) -> (GlobNode, GlobNode) {
        let excludePredicate = (!) • predicate
        return (
            GlobNode(include: self.include.map { $0.filter(predicate) }.map { Set($0) },
                     exclude: self.exclude.map { $0.filter(predicate) }.map { Set($0) }),
            GlobNode(include: self.include.map { $0.filter(excludePredicate) }.map { Set($0) },
                     exclude: self.exclude.map { $0.filter(excludePredicate) }.map { Set($0) })
        )
    }

    public func toSkylark() -> SkylarkNode {
        let tupleSet: AttrSet<AttrTuple<Set<String>, Set<String>>> = include.zip(exclude)
        
        let atLeastList: AttrSet<SkylarkNode> = AttrSet(basic: .list([]))
        
        func render(includes: Set<String>, excludes: Set<String>) -> SkylarkNode {
            // including nothing means excludes won't do anything
            guard !includes.isEmpty else { return .list([]) }
            // if includes are excludes, then this is the same as a no-op
            // guard includes == excludes else { return .list([]) }
            // otherwise we glob
	        return SkylarkNode.functionCall(name: "glob",
                                        arguments: [
                                            .basic(includes.toSkylark())
                                            ] +
                                            (excludes.isEmpty ? [] : [.named(name: "exclude", value: excludes.toSkylark())]) +
                                            [ .named(name: "exclude_directories", value: .int(excludeDirectories ? 1 : 0))
            ])    
        }
        
        let basicIncludes = (tupleSet.basic?.first).denormalize()
        let basicExcludes = (tupleSet.basic?.second).denormalize()
        
        let fromMulti: AttrSet<SkylarkNode> = AttrSet(multi: tupleSet.multi.map { tuple -> SkylarkNode in
            return render(
                includes: basicIncludes <> tuple.first.denormalize(),
                excludes: basicExcludes <> tuple.second.denormalize()
            )
        })
        
        let justBasic: AttrSet<SkylarkNode> =
            AttrSet(basic: render(
                includes: basicIncludes,
                excludes: basicExcludes
	        ))
        
        // This could render three distinct ways
        // 1. If there is nothing in basic or multiplatform, we need at least a list for valid skylark (that's the guard in the render)
        // 2. If there is nothing in multiplatform, we just render the basic glob
        // 3. Otherwise, we inline the basic parts into the multiplatform select (otherwise the glob semantics are broken)
        
        return (fromMulti.isEmpty ? justBasic : fromMulti).toSkylark()
    }
}

extension GlobNode: Equatable {
    public static func == (lhs: GlobNode, rhs: GlobNode) -> Bool {
        return lhs.include == rhs.include && lhs.exclude == rhs.exclude && lhs.excludeDirectories == rhs.excludeDirectories
    }
}

extension GlobNode: EmptyAwareness {
    public var isEmpty: Bool { return include.isEmpty && exclude.isEmpty }
    
    public static var empty: GlobNode {
        return GlobNode(include: AttrSet.empty, exclude: AttrSet.empty)
    }
}

extension GlobNode: Monoid {
    public static func <> (lhs: GlobNode, rhs: GlobNode) -> GlobNode {
        return GlobNode(
            include: lhs.include <> rhs.include,
            exclude: lhs.exclude <> rhs.exclude
        )
    }
}

extension GlobNode {
    enum lens {
        static let include: Lens<GlobNode, AttrSet<Set<String>>> = {
            Lens<GlobNode, AttrSet<Set<String>>>(view: { $0.include }, set: { include, globNode in
                GlobNode(include: include, exclude: globNode.exclude)
            })
        }()

        static let exclude: Lens<GlobNode, AttrSet<Set<String>>> = {
            Lens<GlobNode, AttrSet<Set<String>>>(view: { $0.exclude }, set: { exclude, globNode in
                GlobNode(include: globNode.include, exclude: exclude)
            })
        }()
    }
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
            return compiler.compile(call: call, arguments: arguments)
        case let .skylark(value):
            return value
        case let .list(value):
            return "[\n" + value.map { node in
                "\(SkylarkCompiler.white(indent: indent + 2))\(compile(node))"
            }.joined(separator: ",\n") + "\n\(whitespace)]"
        case let .expr(lhs, op, rhs):
            return compile(lhs) + " \(op) " + compile(rhs)
        case let .dict(dict):
            let compiler = SkylarkCompiler(node, indent: indent + 2)
            return "{\n" + dict.map { key, val in
                "\(SkylarkCompiler.white(indent: indent + 2))\(compiler.compile(.string(key))): \(compiler.compile(val))"
            }.joined(separator: ",\n") + "\n\(whitespace)}"
        case let .lines(lines):
            return lines.map(compile).joined(separator: "\n")
        }
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
