//
//  SkylarkConvertible.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/19/17.
//  Copyright © 2017 jerry. All rights reserved.
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

extension Dictionary: SkylarkConvertible {
    public func toSkylark() -> SkylarkNode {
        return .dict([:] <> self.map { kv in
            let key = kv.0 as! String
            let value = kv.1 as! SkylarkConvertible
            return (key, value.toSkylark())
        })
    }
}
