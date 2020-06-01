//
//  SkylarkConvertible.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/19/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

// SkylarkConvertible is a higher level representation of types within Skylark
public protocol SkylarkConvertible {
    func toSkylark() -> SkylarkNode
}

extension SkylarkNode: SkylarkConvertible {
    public func toSkylark() -> SkylarkNode {
        return self
    }
}

extension SkylarkNode: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }
}

extension SkylarkNode: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}

extension Int: SkylarkConvertible {
    public func toSkylark() -> SkylarkNode {
        return .int(self)
    }
}

extension String: SkylarkConvertible {
    public func toSkylark() -> SkylarkNode {
        return .string(self)
    }
}

extension Array: SkylarkConvertible {
    public func toSkylark() -> SkylarkNode {
        return .list(self.map { x in (x as! SkylarkConvertible).toSkylark() })
    }
}

extension Optional: SkylarkConvertible {
    public func toSkylark() -> SkylarkNode {
        switch self {
        case .none: return SkylarkNode.empty
        case .some(let x): return (x as! SkylarkConvertible).toSkylark()
        }
    }
}

extension Dictionary: SkylarkConvertible {
    public func toSkylark() -> SkylarkNode {
        return .dict([:] <> self.map { kv in
            let key = kv.0 as! String
            let value = kv.1 as! SkylarkConvertible
            return (key, value.toSkylark())
        })
    }
}

extension Set: SkylarkConvertible {
    public func toSkylark() -> SkylarkNode {
        // HACK: Huge hack, but fixing this for real would require major refactoring
        // ASSUMPTION: You're only calling Set.toSkylark on strings!!!
        // FIXME in Swift 4
        return self.map{ $0 as! String }.sorted().toSkylark()
    }
}

extension Bool: SkylarkConvertible {
    public func toSkylark() -> SkylarkNode {
        (self ? 1 : 0).toSkylark()
    }
}