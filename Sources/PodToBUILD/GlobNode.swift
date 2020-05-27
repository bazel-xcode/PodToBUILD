//
//  GlobNode.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 05/21/18.
//  Copyright © 2020 Pinterest Inc. All rights reserved.
//

import Foundation

public struct GlobNode: SkylarkConvertible {
    // Bazel Glob function: glob(include, exclude=[], exclude_directories=1)
    public let include: [Either<Set<String>, GlobNode>]
    public let exclude: [Either<Set<String>, GlobNode>]
    public let excludeDirectories: Bool = true
    static let emptyArg: Either<Set<String>, GlobNode>
        = Either.left(Set([String]()))

    init(include: Set<String> = Set(), exclude: Set<String> = Set()) {
        self.include = [.left(include)]
        self.exclude = [.left(exclude)]
    }

    init(include: Either<Set<String>, GlobNode>, exclude: Either<Set<String>, GlobNode>) {
        self.include = [include]
        self.exclude = [exclude]
    }

    init(include: [Either<Set<String>, GlobNode>], exclude: [Either<Set<String>, GlobNode>]) {
        self.include = include
        self.exclude = exclude
    }

    public func toSkylark() -> SkylarkNode {
        guard isEmpty == false else {
            return .empty
        }

        guard include != exclude else {
            return .empty
        }

        let includeArgs: [SkylarkFunctionArgument] = [
            SkylarkFunctionArgument.basic(self.include.reduce(SkylarkNode.empty) {
                accum, next -> SkylarkNode in
                accum .+. next.toSkylark()
            }),
        ]

        let excludeArgs: [SkylarkFunctionArgument]

        let excludeIsEmpty = exclude.reduce(true) {
            accum, next -> Bool in
            if accum == false {
                return false
            }
            switch next {
            case let .left(val):
                return val.isEmpty
            case let .right(val):
                return val.isEmpty
            }
        }
        excludeArgs = excludeIsEmpty ? [] : [
            SkylarkFunctionArgument.named(name: "exclude", value: self.exclude.reduce(SkylarkNode.empty) {
                accum, next -> SkylarkNode in
                accum .+. next.toSkylark()
            }),
        ]

        let dirArgs: [SkylarkFunctionArgument] = [
            .named(name: "exclude_directories",
                   value: .int(self.excludeDirectories ? 1 : 0)),
        ]
        return SkylarkNode.functionCall(name: "glob",
                                        arguments: includeArgs + excludeArgs + dirArgs)
    }
}

extension Either: Equatable where T == Set<String>, U == GlobNode {
    public static func == (lhs: Either, rhs: Either) -> Bool {
        if case let .left(lhsL) = lhs, case let .left(rhsL) = rhs {
            return lhsL == rhsL
        }
        if case let .right(lhsR) = lhs, case let .right(rhsR) = rhs {
            return lhsR == rhsR
        }
        if case let .left(lhsL) = lhs, case let .right(rhsR) = rhs {
            if lhsL.isEmpty, rhsR.isEmpty {
                return true
            }
        }
        if case let .right(lhsR) = lhs, case let .left(rhsR) = rhs {
            if lhsR.isEmpty, rhsR.isEmpty {
                return true
            }
        }

        return false
    }

    public func map(_ transform: (String) -> String) -> Either<Set<String>, GlobNode> {
        switch self {
        case let .left(setVal):
            return .left(Set(setVal.map(transform)))
        case let .right(globVal):
            return .right(GlobNode(
                include: globVal.include.map {
                    $0.map(transform)
                }, exclude: globVal.exclude.map {
                    $0.map(transform)
                }
            ))
        }
    }
}

extension Array where Iterator.Element == Either<Set<String>, GlobNode> {
    var isEmpty: Bool {
        return self.reduce(true) {
            accum, next -> Bool in
            if accum == false {
                return false
            }
            switch next {
            case .left(let val):
                return val.isEmpty
            case .right(let val):
                return val.isEmpty
            }
        }
    }
}

extension Either: SkylarkConvertible where T == Set<String>, U == GlobNode {
    public func toSkylark() -> SkylarkNode {
        switch self {
        case let .left(setVal):
            return setVal.sorted { $0 < $1 }.toSkylark()
        case let .right(globVal):
            return globVal.toSkylark()
        }
    }
}

extension GlobNode: Equatable {
    public static func == (lhs: GlobNode, rhs: GlobNode) -> Bool {
        return lhs.include == rhs.include
            && lhs.exclude == rhs.exclude
    }
}

extension GlobNode: EmptyAwareness {
    public var isEmpty: Bool {
        // If the include is the same as the exclude then it's empty
        return self.include.isEmpty || self.include == self.exclude
    }

    public static var empty: GlobNode {
        return GlobNode(include: Set(), exclude: Set())
    }
}

extension GlobNode: Monoid {
    public static func <> (_: GlobNode, _: GlobNode) -> GlobNode {
        // Currently, there is no way to implement this reasonablly
        fatalError("cannot combine GlobNode ( added for AttrSet )")
    }
}


extension GlobNode {
    /// Evaluates the glob for all the sources on disk
    public func sourcesOnDisk() -> Set<String> {
        let includedFiles = self.include.reduce(into: Set<String>()) {
            accum, next in
            switch next {
            case .left(let setVal):
                 setVal.forEach { Glob(pattern: $0).paths.forEach { accum.insert($0) } }
            case .right(let globVal):
                 globVal.sourcesOnDisk().forEach { accum.insert($0) }
            }
        }

        let excludedFiles = self.exclude.reduce(into: Set<String>()) {
            accum, next in
            switch next {
            case .left(let setVal):
                 setVal.forEach { Glob(pattern: $0).paths.forEach { accum.insert($0) } }
            case .right(let globVal):
                 globVal.sourcesOnDisk().forEach { accum.insert($0) }
            }
        }
        return includedFiles.subtracting(excludedFiles)
    }

    func hasSourcesOnDisk() -> Bool {
        return sourcesOnDisk().count > 0
    }
}

