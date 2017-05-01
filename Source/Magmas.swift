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


struct Last<T> { let v: T; init(_ v: T) { self.v = v } }
extension Last: Semigroup {
    static func<>(lhs: Last, rhs: Last) -> Last {
        return rhs
    }
}
struct First<T> { let v: T; init(_ v: T) { self.v = v } }
extension First: Semigroup {
    static func<>(lhs: First, rhs: First) -> First {
        return lhs
    }
}

/// Law: empty <> x = x <> empty = x (identity)
public protocol Monoid: Semigroup {
    static var empty: Self { get }
}

public func mfold<M: Monoid>(_ monoids: [M]) -> M {
    return monoids.reduce(M.empty){ $0 <> $1 }
}

public func<> <T: Semigroup>(lhs: T?, rhs: T?) -> T? {
    switch (lhs, rhs) {
    case (.none, _): return rhs
    case (_, .none): return lhs
    case let (.some(x), .some(y)): return .some(x <> y)
    default: fatalError("Swift's exhaustivity checker is bad")
    }
}
// induce the monoid with optional since swift can't handle
// option monoids
public func sfold<S: Semigroup>(_ semigroups: [S?]) -> S? {
    return semigroups.reduce(nil){ $0 <> $1 }
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

struct Trivial { }
extension Trivial: Monoid {
    static func<>(lhs: Trivial, rhs: Trivial) -> Trivial {
        return Trivial()
    }
    
    public static var empty: Trivial { return Trivial() }
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

func const<A, B>(_ b: @autoclosure @escaping () -> B) -> (A) -> B {
    return { _ in b() }
}
