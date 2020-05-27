//
//  Magmas.swift
//  PodToBUILD
//
//  Created by Brandon Kase on 4/28/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

/// Magmas are closed binary operators
/// Watch http://2017.funswiftconf.com/ (Brandon Kase) & (Brandon Williams) if you're confused

infix operator<>: AdditionPrecedence
/// Law: x <> (y <> z) = (x <> y) <> z (associativity)
public protocol Semigroup {
    static func<>(lhs: Self, rhs: Self) -> Self
}

/// A wrapper that takes anything and makes it into something
/// that you can combine by ignoring the first thing
struct Last<T> { let v: T; init(_ v: T) { self.v = v } }
extension Last: Semigroup {
    static func<>(lhs: Last, rhs: Last) -> Last {
        return rhs
    }
}
/// A wrapper that takes anything and makes it into something
/// that you can combine by ignoring the second thing
struct First<T> { let v: T; init(_ v: T) { self.v = v } }
extension First: Semigroup {
    static func<>(lhs: First, rhs: First) -> First {
        return lhs
    }
}

/// A type with some sort of Identity element
public protocol Identity {
    static var empty: Self { get }
}


/// Monoids are the building blocks for clean, reusable,
/// composable code.
///
/// Assuming you have an empty and a <> that obeys the laws
/// You can freely lift expressions into functions or lower
/// let bindings into subexpressions. You have ultimate power
///
/// Law: empty <> x = x <> empty = x (identity)
public protocol Monoid: Semigroup, Identity {}

public func mfold<M: Monoid>(_ monoids: [M]) -> M {
    return monoids.reduce(M.empty){ $0 <> $1 }
}

/// This is a hack since Swift doesn't have conditional conformances
infix operator<+>: AdditionPrecedence
public func<+> <T: Semigroup>(lhs: T?, rhs: T?) -> T? {
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
    return semigroups.reduce(nil){ $0 <+> $1 }
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
    /// Override with the stuff on the right
    /// [b:1] <> [b:2] => [b:2]
    public static func<><Dictish: Collection>(lhs: Dictionary, rhs: Dictish) -> Dictionary where Dictish.Iterator.Element == Dictionary.Element {
        return rhs.reduce(lhs) { (acc: Dictionary, kv: (Key, Value)) in
            var d = acc
            d[kv.0] = kv.1
            return d
        }
    }

    public static var empty: Dictionary { return [:] }
}

extension Optional: Monoid {
    public static func <>(lhs: Optional, rhs: Optional) -> Optional {
        switch (lhs, rhs) {
        case (.none, _): return rhs
        case (.some, .some): return lhs <> rhs
        case (.some, _): return lhs
        case (_, .some): return rhs
        }
    }
    public static var empty: Optional { return nil }
}

extension Set: Monoid {
    public static var empty: Set<Element> { return [] }

    /// Override with the stuff on the right
    /// [Fred1] <> [Fred2] => [Fred2] (assuming Fred1 == Fred2)
    public static func<>(lhs: Set, rhs: Set) -> Set {
        var base = Set<Element>()
        rhs.forEach { base.insert($0) }
        lhs.forEach { base.insert($0) }
        return base
    }
}

/// Used when you need a monoid for some constraint but you really didn't care about the value
/// This is just a wrapper for the `()` type in Swift
struct Trivial { }
extension Trivial: Monoid {
    static func<>(lhs: Trivial, rhs: Trivial) -> Trivial {
        return Trivial()
    }
    
    public static var empty: Trivial { return Trivial() }
}

/// Law: forall x. x.isEmpty => x is `empty`
public protocol EmptyAwareness: Identity {
    var isEmpty: Bool { get }
}

/// If we have an optional of a monoid there are two empties
/// The empty for monoid or nil
/// normalize uses nil; denormalize uses the empty
extension Optional where Wrapped: Monoid & EmptyAwareness {
    public func normalize() -> Optional {
        return flatMap { $0.isEmpty ? nil : $0 }
    }

    public func denormalize() -> Wrapped {
        return self ?? Wrapped.empty
    }
}

extension String: EmptyAwareness {}

extension Array: EmptyAwareness {}
extension Dictionary: EmptyAwareness {}
extension Optional {
    public var isEmptyAwareEmpty: Bool {
        return false
    }
}

extension Optional where Wrapped: EmptyAwareness {
    public var isEmptyAwareEmpty: Bool {
        switch self {
        case .none: return true
        case .some(let val): return val.isEmpty 
        }
    }
}


extension Optional: EmptyAwareness {
    public var isEmpty: Bool {
        switch self {
        case .none: return true
        case .some: return self.isEmptyAwareEmpty
        }
    }
}

extension Set: EmptyAwareness {}

/// Lift a value into a public function that ignores it's input
/// Example: I have an (x: Int)
///         I want a (String) -> Int
///         const(x): (String) -> Int
public func const<A, B>(_ b: @autoclosure @escaping () -> B) -> (A) -> B {
    return { _ in b() }
}

/// Pipe forward just lets you turn a pipeline of transformations
/// `f then g then h` from the illogical `h(g(f(x)))` to `x |> f |> g |> h`
/// Another way to think about it is "calling methods" with free public functions
precedencegroup PipeForward {
    associativity: left
    lowerThan: TernaryPrecedence
    higherThan: AssignmentPrecedence
}
infix operator |>: PipeForward
public func |><T,U>(x: T, f: (T) -> U) -> U {
    return f(x)
}

public indirect enum Either<T,U> {
    case left(T)
    case right(U)
    
    public func fold<R>(left: (T) -> R, right: (U) -> R) -> R {
        switch self {
        case let .left(t): return left(t)
        case let .right(u): return right(u)
        }
    }
}
