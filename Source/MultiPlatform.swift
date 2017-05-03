//
//  MultiPlatform.swift
//  PodSpecToBUILD
//
//  Created by Brandon Kase on 4/28/17.
//  Copyright © 2017 jerry. All rights reserved.
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
    let ios: T?
    let osx: T?
    let watchos: T?
    let tvos: T?
    
    public static var empty: MultiPlatform<T> { return MultiPlatform(ios: nil, osx: nil, watchos: nil, tvos: nil) }

    public var isEmpty: Bool { return ios == nil && osx == nil && watchos == nil && tvos == nil }

    // overwrites the value with the one on the right
    public static func<>(lhs: MultiPlatform, rhs: MultiPlatform) -> MultiPlatform {
        return MultiPlatform(
            ios: lhs.ios <> rhs.ios,
            osx: lhs.osx <> rhs.osx,
            watchos: lhs.watchos <> rhs.watchos,
            tvos: lhs.tvos <> rhs.tvos
        )
    }

    init(ios: T?, osx: T?, watchos: T?, tvos: T?) {
        self.ios = ios.normalize()
        self.osx = osx.normalize()
        self.watchos = watchos.normalize()
        self.tvos = tvos.normalize()
    }

    init(ios: T?) {
        self.ios = ios.normalize()
        self.osx = nil
        self.watchos = nil
        self.tvos = nil
    }

    init(osx: T?) {
        self.osx = osx.normalize()
        self.ios = nil
        self.watchos = nil
        self.tvos = nil
    }

    init(watchos: T?) {
        self.watchos = watchos.normalize()
        self.ios = nil
        self.osx = nil
        self.tvos = nil
    }

    init(tvos: T?) {
        self.tvos = tvos.normalize()
        self.ios = nil
        self.osx = nil
        self.watchos = nil
    }

    init(value: T) {
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
            osx.map { [":\(SelectCase.osx.rawValue)": $0] } <>
            watchos.map { [":\(SelectCase.watchos.rawValue)": $0] } <>
            tvos.map { [":\(SelectCase.tvos.rawValue)": $0] } <>
            // TODO: Change to T.empty and move ios up when we support other platforms
	        [SelectCase.fallback.rawValue: ios ?? T.empty ] ?? [:]
        ).toSkylark())])
    }
}


struct AttrTuple<A: AttrSetConstraint, B: AttrSetConstraint>: AttrSetConstraint {
    let first: A?
    let second: B?

    init(_ arg1: A?, _ arg2: B?) {
        first = arg1
        second = arg2
    }

    public static func <> (lhs: AttrTuple, rhs: AttrTuple) -> AttrTuple {
        return AttrTuple(
          lhs.first <> rhs.first,
          lhs.second <> rhs.second
        )
    }

    public static var empty: AttrTuple { return AttrTuple(nil, nil) }

    public var isEmpty: Bool { return first == nil && second == nil }


    func toSkylark() -> SkylarkNode {
        fatalError("You tried to toSkylark on a tuple (our domain modelling failed here :( )")
    }
}

struct AttrSet<T: AttrSetConstraint>: Monoid, SkylarkConvertible, EmptyAwareness {
    let basic: T?
    let multi: MultiPlatform<T>
    
    init(basic: T?) {
        self.basic = basic.normalize()
        multi = MultiPlatform.empty
    }

    init(multi: MultiPlatform<T>) {
        basic = nil
        self.multi = multi
    }

    init(basic: T?, multi: MultiPlatform<T>) {
        self.basic = basic.normalize()
        self.multi = multi
    }

    func map<U: AttrSetConstraint>(_ transform: (T) -> U) -> AttrSet<U> {
        return AttrSet<U>(basic: basic.map(transform), multi: multi.map(transform))
    }

    func fold<U>(basic: (T?) -> U, multi: (U, MultiPlatform<T>) -> U) -> U {
        return multi(basic(self.basic), self.multi)
    }

    func zip<U>(_ other: AttrSet<U>) -> AttrSet<AttrTuple<T,U>> {
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

    static var empty: AttrSet<T> { return AttrSet(basic: nil, multi: MultiPlatform.empty) }

    public var isEmpty: Bool {
        return basic == nil && multi.isEmpty
    }

    static func<>(lhs: AttrSet<T>, rhs: AttrSet<T>) -> AttrSet<T> {
        return AttrSet(
            basic: lhs.basic <> rhs.basic,
            multi: lhs.multi <> rhs.multi
        )
    }

    func toSkylark() -> SkylarkNode {
        switch basic {
        case .none where multi.isEmpty: return T.empty.toSkylark()
        case let .some(b) where multi.isEmpty: return b.toSkylark()
        case .none: return multi.toSkylark()
        case let .some(b): return b.toSkylark() .+. multi.toSkylark()
        }
    }
}


extension Dictionary {
    init<S: Sequence>(tuples: S) where S.Iterator.Element == (Key, Value) {
        self = tuples.reduce([:]) { d, t in d <> [t.0:t.1] }
    }
}

extension AttrSet {
    static func sequence<K: Hashable, V: AttrSetConstraint>(attrSet attrOfDict: AttrSet<[K:V]>) -> [K: AttrSet<V>] {
        return attrOfDict.fold(
            basic: { dictOpt in
                let dict: [K: V] = (dictOpt ?? [K:V]())
                return Dictionary<K,AttrSet<V>>(tuples: dict.map{ k, v in
                    (k, AttrSet<V>(basic: v))
                })
        }, multi: { (acc: [K: AttrSet<V>], multi: MultiPlatform<[K:V]>) in
            let iosDict: [K: V] = (multi.ios ?? [:])
            let ios: [K: AttrSet<V>] = Dictionary<K, AttrSet<V>>(tuples: iosDict.map{ k, v in
                (k, AttrSet<V>(multi: MultiPlatform(ios: v)))
            })

            let osxDict: [K: V] = (multi.osx ?? [:])
            let osx: [K: AttrSet<V>] = Dictionary<K, AttrSet<V>>(tuples: osxDict.map{ k, v in
                (k, AttrSet<V>(multi: MultiPlatform(osx: v)))
            })

            let watchDict: [K: V] = (multi.watchos ?? [:])
            let watch: [K: AttrSet<V>] = Dictionary<K, AttrSet<V>>(tuples: watchDict.map{ k, v in
                (k, AttrSet<V>(multi: MultiPlatform(watchos: v)))
            })

            let tvosDict: [K: V] = (multi.tvos ?? [:])
            let tvos: [K: AttrSet<V>] = Dictionary<K, AttrSet<V>>(tuples: tvosDict.map { k, v in
                (k, AttrSet<V>(multi: MultiPlatform(tvos: v)))
            })

            return acc <> ios <> osx <> watch <> tvos
        })
    }
}


// Because we don't have conditional conformance we have to specialize these
extension Optional where Wrapped == Array<String> {
    static func == (lhs: Optional, rhs: Optional) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case let (.some(x), .some(y)): return x == y
        case (_, _): return false
        }
    }
}
extension MultiPlatform where T == [String] {
    static func == (lhs: MultiPlatform, rhs: MultiPlatform) -> Bool {
        return lhs.ios == rhs.ios && lhs.osx == rhs.osx && lhs.watchos == rhs.watchos && lhs.tvos == rhs.tvos
    }
}
extension AttrSet where T == [String] {
    static func == (lhs: AttrSet, rhs: AttrSet) -> Bool {
        return lhs.basic == rhs.basic && lhs.multi == rhs.multi
    }
}

// for extracting attr sets
func liftToAttr<Part>(_ lens: Lens<PodSpecRepresentable, Part>) -> Lens<PodSpec, AttrSet<Part>>
    where Part: Monoid & SkylarkConvertible & EmptyAwareness {
        let optLens = liftOpt(lens)
        return ReadonlyLens { (spec: PodSpec) -> AttrSet<Part> in
            AttrSet(basic: spec ^* lens) <> AttrSet(multi: MultiPlatform(
                ios: spec ^* (PodSpec.lens.ios >•> optLens),
                osx: spec ^* (PodSpec.lens.osx >•> optLens),
                watchos: spec ^* (PodSpec.lens.watchos >•> optLens),
                tvos: spec ^* (PodSpec.lens.tvos >•> optLens)
            ))
        }
}
