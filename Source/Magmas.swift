//
//  Magmas.swift
//  PodSpecToBUILD
//
//  Created by Brandon Kase on 4/28/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

/// Magmas are closed binary operators

infix operator<>: AdditionPrecedence
/// Law: x <> (y <> z) = (x <> y) <> z (associativity)
public protocol Semigroup {
    static func<>(lhs: Self, rhs: Self) -> Self
}

/// Law: empty <> x = x <> empty = x (identity)
public protocol Monoid: Semigroup {
    static var empty: Self { get }
}

public func<> <T: Semigroup>(lhs: T?, rhs: T?) -> T? {
    switch (lhs, rhs) {
    case (.none, _): return rhs
    case (_, .none): return lhs
    case let (.some(x), .some(y)): return .some(x <> y)
    default: fatalError("Swift's exhaustivity checker is bad")
    }
}

extension Array: Monoid {
    public static func <>(lhs: Array, rhs: Array) -> Array {
        return lhs + rhs
    }

    public static var empty: Array { return [] }
}

extension String: Monoid {
    public static func <>(lhs: String, rhs: String) -> String {
        return lhs + rhs
    }

    public static var empty: String = ""
}

extension Dictionary: Monoid {
    public static func<><Dictish: Collection>(lhs: Dictionary, rhs: Dictish) -> Dictionary where Dictish.Iterator.Element == Dictionary.Element {
        return rhs.reduce(lhs) { (acc: Dictionary, kv: (Key, Value)) in
            var d = acc
            d[kv.0] = kv.1
            return d
        }
    }

    public static var empty: Dictionary { return [:] }
}

public protocol EmptyAwareness {
    var isEmpty: Bool { get }
}

extension Optional where Wrapped: Monoid & EmptyAwareness {
    func normalize() -> Optional {
        return flatMap { $0.isEmpty ? nil : $0 }
    }
}

extension String: EmptyAwareness {}
extension Array: EmptyAwareness {}
extension Dictionary: EmptyAwareness {}
