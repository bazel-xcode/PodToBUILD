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

    public var isEmpty: Bool { return ios == nil && osx == nil && watchos == nil && tvos == nil }

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

extension MultiPlatform {
    public enum lens {
        public static func ios() -> Lens<MultiPlatform<T>, T?> {
	        return Lens(view: { $0.ios }, set: { ios, multi in
		        MultiPlatform(
                    ios: ios,
                    osx: multi.osx,
                    watchos: multi.watchos,
                    tvos: multi.tvos
                )
            })
        }
        
        public static func osx() -> Lens<MultiPlatform<T>, T?> {
	        return Lens(view: { $0.osx }, set: { osx, multi in
		        MultiPlatform(
                    ios: multi.ios,
                    osx: osx,
                    watchos: multi.watchos,
                    tvos: multi.tvos
                )
            })
        }
        
        public static func watchos() -> Lens<MultiPlatform<T>, T?> {
	        return Lens(view: { $0.watchos }, set: { watchos, multi in
		        MultiPlatform(
                    ios: multi.ios,
                    osx: multi.osx,
                    watchos: watchos,
                    tvos: multi.tvos
                )
            })
        }
        
        public static func tvos() -> Lens<MultiPlatform<T>, T?> {
	        return Lens(view: { $0.tvos }, set: { tvos, multi in
		        MultiPlatform(
                    ios: multi.ios,
                    osx: multi.osx,
                    watchos: multi.watchos,
                    tvos: tvos
                )
            })
        }
        
        public static func viewAll<U: Semigroup>(f: @escaping (T) -> U) -> ((MultiPlatform<T>) -> U?) {
	        return { whole in
                (whole ^* MultiPlatform<T>.lens.ios()).map(f) <>
                (whole ^* MultiPlatform<T>.lens.osx()).map(f) <>
                (whole ^* MultiPlatform<T>.lens.watchos()).map(f) <>
                (whole ^* MultiPlatform<T>.lens.tvos()).map(f)
            }
        }
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

    public static var empty: AttrTuple { return AttrTuple(nil, nil) }

    public var isEmpty: Bool { return first == nil && second == nil }


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
        return basic == nil && multi.isEmpty
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
    public enum lens {
        public static func basic() -> Lens<AttrSet<T>, T?> {
            return Lens<AttrSet<T>, T?>(view: { $0.basic }, set: { (basic: T?, attrSet: AttrSet<T>) -> AttrSet<T> in
                AttrSet<T>(basic: basic, multi: attrSet.multi)
            })
        }
        
        public static func multi() -> Lens<AttrSet<T>, MultiPlatform<T>> {
            return Lens<AttrSet<T>, MultiPlatform<T>>(view: { $0.multi }, set: { multi, attrSet in
                AttrSet<T>(basic: attrSet.basic, multi: multi)
            })
        }
    }
}


extension Dictionary {
    public init<S: Sequence>(tuples: S) where S.Iterator.Element == (Key, Value) {
        self = tuples.reduce([:]) { d, t in d <> [t.0:t.1] }
    }
}

extension AttrSet {
    public static func sequence<K, V: AttrSetConstraint>(attrSet attrOfDict: AttrSet<[K:V]>) -> [K: AttrSet<V>] {
        return attrOfDict.fold(
            basic: { dictOpt in
                let dict: [K: V] = (dictOpt ?? [K:V]())
                return Dictionary<K,AttrSet<V>>(tuples: dict.map{ k, v in
                    (k, AttrSet<V>(basic: v))
                })
        }, multi: { (acc: [K: AttrSet<V>], multi: MultiPlatform<[K:V]>) in
            let inner: [K: AttrSet<V>]? = multi |>
                MultiPlatform<[K:V]>.lens.viewAll{ (dict: [K:V]) -> [K: AttrSet<V>] in
                    Dictionary<K, AttrSet<V>>(tuples: dict.map{ k, v in
                    (k, AttrSet<V>(multi: MultiPlatform(ios: v)))
                }) }
            
            return acc <> inner.denormalize()
        })
    }
    
    /// A sequence operation takes something of the form `F<G<?>>` and turns it into a `G<F<?>>` for some F and G
    /// In this case, `F = AttrSet`, `G = some Sequence S` (and since Swift is limited in it's expressiveness, we'll return an array)
    /// So we're turning an `AttrSet<S<?>>` into an `[AttrSet<?>]` where the `[]` are morally the `S`
    public static func sequenceSeq<S: Sequence, T: AttrSetConstraint>(attrSet attrOfArr: AttrSet<S>) -> [AttrSet<T>]
	    where S.Iterator.Element == T {
        return attrOfArr.fold(basic: { (arr: S?) -> [AttrSet<T>] in
            let arr: [T] = Array(arr ?? S.empty)
            return arr.map{ (t: T) -> AttrSet<T> in AttrSet<T>(basic: t) }
        }, multi: { (arrOfAttr: [AttrSet<T>], multiOfArr: MultiPlatform<S>) -> [AttrSet<T>] in
            let ios: [AttrSet<T>] = multiOfArr.ios.denormalize().map{ (t: T) -> AttrSet<T> in AttrSet<T>(multi: MultiPlatform<T>(ios: t)) }
            let osx: [AttrSet<T>] = multiOfArr.osx.denormalize().map{ (t: T) -> AttrSet<T> in AttrSet<T>(multi: MultiPlatform<T>(osx: t)) }
            let tvos: [AttrSet<T>] = multiOfArr.tvos.denormalize().map{ (t: T) -> AttrSet<T> in AttrSet<T>(multi: MultiPlatform<T>(tvos: t)) }
            let watchos: [AttrSet<T>] = multiOfArr.watchos.denormalize().map{ (t: T) -> AttrSet<T> in AttrSet<T>(multi: MultiPlatform<T>(watchos: t)) }
            
            return arrOfAttr <> ios <> osx <> watchos <> tvos
        })
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
}
extension AttrSet where T == Set<String> {
    public static func == (lhs: AttrSet, rhs: AttrSet) -> Bool {
        return lhs.basic == rhs.basic && lhs.multi == rhs.multi
    }   
}

// for extracting attr sets
public func liftToAttr<Part>(_ lens: Lens<PodSpecRepresentable, Part>) -> Lens<PodSpec, AttrSet<Part>>
    where Part: Monoid & SkylarkConvertible & EmptyAwareness {
        let optLens = lens.opt
        return ReadonlyLens { (spec: PodSpec) -> AttrSet<Part> in
            AttrSet(basic: spec ^* lens) <> AttrSet(multi: MultiPlatform(
                ios: spec ^* (PodSpec.lens.ios >•> optLens),
                osx: spec ^* (PodSpec.lens.osx >•> optLens),
                watchos: spec ^* (PodSpec.lens.watchos >•> optLens),
                tvos: spec ^* (PodSpec.lens.tvos >•> optLens)
            ))
        }
}
