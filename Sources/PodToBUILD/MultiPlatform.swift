//
//  MultiPlatform.swift
//  PodToBUILD
//
//  Created by Brandon Kase on 4/28/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

enum SelectCase: String {
    case ios = "iosCase"
    case osx = "osxCase"
    case watchos = "watchosCase"
    case tvos = "tvosCase"
    case fallback = "//conditions:default"
}

public typealias AttrSetConstraint = Monoid & SkylarkConvertible & EmptyAwareness

public struct MultiPlatform<T: AttrSetConstraint>: Monoid, SkylarkConvertible, EmptyAwareness {
    public let ios: T?
    public let osx: T?
    public let watchos: T?
    public let tvos: T?
    
    public static var empty: MultiPlatform<T> { return MultiPlatform(ios: nil, osx: nil, watchos: nil, tvos: nil) }

    public var isEmpty: Bool {
        return (ios == nil || ios.isEmpty)
            && (osx == nil || osx.isEmpty)
            && (watchos == nil || watchos.isEmpty)
            && (tvos == nil || tvos.isEmpty)
    }

    // overwrites the value with the one on the right
    public static func<>(lhs: MultiPlatform, rhs: MultiPlatform) -> MultiPlatform {
        return MultiPlatform(
            ios: lhs.ios <+> rhs.ios,
            osx: lhs.osx <+> rhs.osx,
            watchos: lhs.watchos <+> rhs.watchos,
            tvos: lhs.tvos <+> rhs.tvos
        )
    }

    public init(ios: T?, osx: T?, watchos: T?, tvos: T?) {
        self.ios = ios.normalize()
        self.osx = osx.normalize()
        self.watchos = watchos.normalize()
        self.tvos = tvos.normalize()
    }

    public init(ios: T?) {
        self.ios = ios.normalize()
        self.osx = nil
        self.watchos = nil
        self.tvos = nil
    }

    public init(osx: T?) {
        self.osx = osx.normalize()
        self.ios = nil
        self.watchos = nil
        self.tvos = nil
    }

    public init(watchos: T?) {
        self.watchos = watchos.normalize()
        self.ios = nil
        self.osx = nil
        self.tvos = nil
    }

    public init(tvos: T?) {
        self.tvos = tvos.normalize()
        self.ios = nil
        self.osx = nil
        self.watchos = nil
    }

    public init(value: T?) {
        self.init(ios: value, osx: value, watchos: value, tvos: value)
    }

    func map<U: AttrSetConstraint>(_ transform: (T) -> U) -> MultiPlatform<U> {
        return MultiPlatform<U>(ios: ios.map(transform),
                                osx: osx.map(transform),
                                watchos: watchos.map(transform),
                                tvos: tvos.map(transform))
    }
    
    public func toSkylark() -> SkylarkNode {
        precondition(ios != nil || osx != nil || watchos != nil || tvos != nil, "MultiPlatform empty can't be rendered")

        return .functionCall(name: "select", arguments: [.basic((
            osx.map { [":\(SelectCase.osx.rawValue)": $0] } <+>
            watchos.map { [":\(SelectCase.watchos.rawValue)": $0] } <+>
            tvos.map { [":\(SelectCase.tvos.rawValue)": $0] } <+>
            // TODO: Change to T.empty and move ios up when we support other platforms
	        [SelectCase.fallback.rawValue: ios ?? T.empty ] ?? [:]
        ).toSkylark())])
    }
}

public struct AttrTuple<A: AttrSetConstraint, B: AttrSetConstraint>: AttrSetConstraint {
    public let first: A?
    public let second: B?

    public init(_ arg1: A?, _ arg2: B?) {
        first = arg1
        second = arg2
    }

    public static func <> (lhs: AttrTuple, rhs: AttrTuple) -> AttrTuple {
        return AttrTuple(
          lhs.first <+> rhs.first,
          lhs.second <+> rhs.second
        )
    }

    public static var empty: AttrTuple {
        return AttrTuple(nil, nil)
    }

    public var isEmpty: Bool {
        return (first == nil || first.isEmpty) &&
            (second == nil || second.isEmpty)
    }

    public func toSkylark() -> SkylarkNode {
        fatalError("You tried to toSkylark on a tuple (our domain modelling failed here :( )")
    }
}

public struct AttrSet<T: AttrSetConstraint>: Monoid, SkylarkConvertible, EmptyAwareness {
    let basic: T?
    let multi: MultiPlatform<T>

    public init(value: T?) {
        self.basic = value.normalize()
        self.multi = MultiPlatform(value: value)
    }

    public init(basic: T?) {
        self.basic = basic.normalize()
        multi = MultiPlatform.empty
    }

    public init(multi: MultiPlatform<T>) {
        basic = nil
        self.multi = multi
    }

    public init(basic: T?, multi: MultiPlatform<T>) {
        self.basic = basic.normalize()
        self.multi = multi
    }

    public func partition(predicate: @escaping (T) -> Bool) -> (AttrSet<T>, AttrSet<T>) {
        return (self.filter(predicate), self.filter { x in !predicate(x) })
    }

    public func map<U: AttrSetConstraint>(_ transform: (T) -> U) -> AttrSet<U> {
        return AttrSet<U>(basic: basic.map(transform), multi: multi.map(transform))
    }

    public func filter(_ predicate: (T) -> Bool) -> AttrSet<T> {
        let basicPass = self.basic.map { predicate($0) ? $0 : T.empty }
        let multiPass = self.multi.map { predicate($0) ? $0 : T.empty }
        return AttrSet<T>(basic: basicPass, multi: multiPass)
    }
    
    public func fold<U>(basic: (T?) -> U, multi: (U, MultiPlatform<T>) -> U) -> U {
        return multi(basic(self.basic), self.multi)
    }

    public func zip<U>(_ other: AttrSet<U>) -> AttrSet<AttrTuple<T,U>> {
        return AttrSet<AttrTuple<T,U>>(
            basic: AttrTuple(self.basic, other.basic),
            multi: MultiPlatform<AttrTuple<T, U>>(
                ios: AttrTuple(self.multi.ios, other.multi.ios),
                osx: AttrTuple(self.multi.osx, other.multi.osx),
                watchos: AttrTuple(self.multi.watchos, other.multi.watchos),
                tvos: AttrTuple(self.multi.tvos, other.multi.tvos)
            )
        )
    }

    public static var empty: AttrSet<T> { return AttrSet(basic: nil, multi: MultiPlatform.empty) }

    public var isEmpty: Bool {
        return (basic == nil || basic.isEmpty)
            && (multi.isEmpty)
    }

    public static func<>(lhs: AttrSet<T>, rhs: AttrSet<T>) -> AttrSet<T> {
        return AttrSet(
            basic: lhs.basic <+> rhs.basic,
            multi: lhs.multi <> rhs.multi
        )
    }

    public func toSkylark() -> SkylarkNode {
        switch basic {
        case .none where multi.isEmpty: return T.empty.toSkylark()
        case let .some(b) where multi.isEmpty: return b.toSkylark()
        case .none: return multi.toSkylark()
        case let .some(b): return b.toSkylark() .+. multi.toSkylark()
        }
    }
}
extension MultiPlatform where T == Optional<String> {
    public func denormalize() -> MultiPlatform<String> {
        return self.map { $0.denormalize() }
    }
}
extension AttrSet where T == Optional<String> {
    public func denormalize() -> AttrSet<String> {
        return self.map { $0.denormalize() }
    }
}

extension AttrSet {
    /// This makes all the code operate on a multi platform
    public func unpackToMulti() -> AttrSet {
        // This converts to multi platform as an LCD
	// Note in later FBSDKCoreKits, this should inherit.
        if let basic = self.basic {
            return AttrSet(multi: MultiPlatform(
                    ios: basic <+> self.multi.ios,
                    osx: basic <+> self.multi.osx,
                    watchos: basic <+> self.multi.watchos,
                    tvos: basic <+> self.multi.tvos
                ))
        }
        return self
    }
}

extension AttrSet where T: AttrSetConstraint, T: Equatable {
    public func flattenToBasicIfPossible() -> AttrSet {
        if self.isEmpty {
            return self
        }
        if self.basic == nil && self.multi.ios == self.multi.osx &&
         self.multi.osx == self.multi.watchos &&
         self.multi.watchos == self.multi.tvos {
             return AttrSet(basic: self.multi.ios)
        }
        return self
    }

    /// For simplicity of the BUILD file, we'll condense if all is the same
    public func toSkylark() -> SkylarkNode {
        let renderable = self.flattenToBasicIfPossible()
        switch renderable.basic {
        case .none where renderable.multi.isEmpty: return T.empty.toSkylark()
        case let .some(b) where renderable.multi.isEmpty: return b.toSkylark()
        case .none: return renderable.multi.toSkylark()
        case let .some(b): return b.toSkylark() .+. renderable.multi.toSkylark()
        }
    }
}

extension Dictionary {
    public init<S: Sequence>(tuples: S) where S.Iterator.Element == (Key, Value) {
        self = tuples.reduce([:]) { d, t in d <> [t.0:t.1] }
    }
}

// Because we don't have conditional conformance we have to specialize these
extension Optional where Wrapped == Array<String> {
    public static func == (lhs: Optional, rhs: Optional) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case let (.some(x), .some(y)): return x == y
        case (_, _): return false
        }
    }
}

extension MultiPlatform where T == [String] {
    public static func == (lhs: MultiPlatform, rhs: MultiPlatform) -> Bool {
        return lhs.ios == rhs.ios && lhs.osx == rhs.osx && lhs.watchos == rhs.watchos && lhs.tvos == rhs.tvos
    }

    func sorted(by areInIncreasingOrder: (String, String) throws -> Bool) rethrows
-> MultiPlatform<T> {
        return try MultiPlatform(
                ios: ios?.sorted(by: areInIncreasingOrder),
                osx: osx?.sorted(by: areInIncreasingOrder),
                watchos: watchos?.sorted(by: areInIncreasingOrder),
                tvos: tvos?.sorted(by: areInIncreasingOrder)
                )
    }
}

extension MultiPlatform where T == Set<String> {
    public static func == (lhs: MultiPlatform, rhs: MultiPlatform) -> Bool {
        return lhs.ios == rhs.ios && lhs.osx == rhs.osx && lhs.watchos == rhs.watchos && lhs.tvos == rhs.tvos
    }   
}

extension AttrSet where T == [String] {
    public static func == (lhs: AttrSet, rhs: AttrSet) -> Bool {
        return lhs.basic == rhs.basic && lhs.multi == rhs.multi
    }

    func sorted(by areInIncreasingOrder: (String, String) throws -> Bool) rethrows
-> AttrSet<T> {
        return try AttrSet(
                basic: basic?.sorted(by: areInIncreasingOrder),
                multi: multi.sorted(by: areInIncreasingOrder)
                )
    }
}

extension AttrSet where T == Set<String> {
    public static func == (lhs: AttrSet, rhs: AttrSet) -> Bool {
        return lhs.basic == rhs.basic && lhs.multi == rhs.multi
    }   
}
extension PodSpec {
    public func attr<T>(_ keyPath: KeyPath<PodSpecRepresentable, T>) -> AttrSet<T> {
        return getAttrSet(spec: self, keyPath: keyPath)
    }
}

// for extracting attr sets
// The key reason that we have this code is to:
// - merge the spec.ios.attr spec.attr
public func getAttrSet<T>(spec: PodSpec, keyPath: KeyPath<PodSpecRepresentable, T>) -> AttrSet<T> {
    let value = spec[keyPath: keyPath]
    return AttrSet(basic: value) <> AttrSet(multi: MultiPlatform(
        ios: spec.ios?[keyPath: keyPath],
        osx: spec.osx?[keyPath: keyPath],
        watchos: spec.watchos?[keyPath: keyPath],
        tvos: spec.tvos?[keyPath: keyPath])
    )
}

