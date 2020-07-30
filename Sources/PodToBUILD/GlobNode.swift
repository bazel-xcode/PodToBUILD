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

    public init(include: Set<String> = Set(), exclude: Set<String> = Set()) {
        self.init(include:  [.left(include)], exclude: [.left(exclude)])
    }

    public init(include: Either<Set<String>, GlobNode>, exclude: Either<Set<String>, GlobNode>) {
        self.init(include:  [include], exclude: [exclude])
    }

    public init(include: [Either<Set<String>, GlobNode>] = [], exclude: [Either<Set<String>, GlobNode>] = []) {
        // Upon allocation, form the most simple version of the glob
        self.include = include.simplify()
        self.exclude = exclude.simplify()
    }

    public func toSkylark() -> SkylarkNode {
        // An empty glob doesn't need to be rendered
        guard isEmpty == false else {
            return .empty
        }

        let include = self.include
        let exclude = self.exclude
        let includeArgs: [SkylarkFunctionArgument] = [
            .basic(include.reduce(SkylarkNode.empty) {
                $0 .+. $1.toSkylark()
            }),
        ]

        // If there's no excludes omit the argument
        let excludeArgs: [SkylarkFunctionArgument] = exclude.isEmpty ? [] : [
            .named(name: "exclude", value: exclude.reduce(SkylarkNode.empty) {
                $0 .+. $1.toSkylark()
            }),
        ]

        // Omit the default argument for exclude_directories
        let dirArgs: [SkylarkFunctionArgument] = self.excludeDirectories ? [] : [
            .named(name: "exclude_directories",
                   value: .int(self.excludeDirectories ? 1 : 0)),
        ]

        return .functionCall(name: "glob",
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

    public func compactMapInclude(_ transform: (String) -> String?) -> Either<Set<String>, GlobNode> {
        switch self {
        case let .left(setVal):
            return .left(Set(setVal.compactMap(transform)))
        case let .right(globVal):
            let inc = globVal.include.compactMap({
                    $0.compactMapInclude(transform)
                })
            return .right(GlobNode(
                include: inc, exclude: globVal.exclude))
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

    public func simplify() -> [Either<Set<String>, GlobNode>] {
        // First simplify the elements and then filter the empty elements
        return self
        .map { $0.simplify() }
        .filter {
            element in
            switch element {
            case let .left(val):
                return !val.isEmpty
            case let .right(val):
                return !val.isEmpty
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

    public func simplify() -> Either<Set<String>, GlobNode> {
        // Recursivly simplfies the globs
        switch self {
        case let .left(val):
            // Base case, this is as simple as it gets
            return .left(val)
        case let .right(val):
            let include = val.include.simplify()
            let exclude = val.exclude.simplify()
            if exclude.isEmpty {
                // When there is no excludes we can do the following:
                // 1. smash all sets into a single set
                // 2. return a set if there are no other globs
                // 3. otherwise, return a simplified glob with 1 set and
                // remaining globs
                var setAccum: Set<String> = Set()
                let remainingGlobs = include
                    .reduce(into: [Either<Set<String>, GlobNode>]()) {
                    accum, next in
                    switch next {
                    case let .left(val):
                        setAccum = setAccum <> val
                    case let .right(val):
                        if !val.isEmpty {
                            accum.append(next)
                        }
                    }
                }

                // If there are no remaining globs, simplify to a set
                if remainingGlobs.count == 0 {
                    return .left(setAccum)
                } else {
                    return .right(GlobNode(include: remainingGlobs + [.left(setAccum)]))
                }
            } else {
                return .right(GlobNode(include: include, exclude: exclude))
            }
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
                 setVal.forEach { podGlob(pattern: $0).forEach { accum.insert($0) } }
            case .right(let globVal):
                 globVal.sourcesOnDisk().forEach { accum.insert($0) }
            }
        }

        let excludedFiles = self.exclude.reduce(into: Set<String>()) {
            accum, next in
            switch next {
            case .left(let setVal):
                 setVal.forEach { podGlob(pattern: $0).forEach { accum.insert($0) } }
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

