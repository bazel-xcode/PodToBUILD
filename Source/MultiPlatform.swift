//
//  MultiPlatform.swift
//  PodSpecToBUILD
//
//  Created by Brandon Kase on 4/28/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

public struct MultiPlatform<T: Monoid & SkylarkConvertible & EmptyAwareness>: Monoid, SkylarkConvertible, EmptyAwareness {
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

    init(value: T) {
        self.init(ios: value, osx: value, watchos: value, tvos: value)
    }

    public func toSkylark() -> SkylarkNode {
        precondition(ios != nil || osx != nil || watchos != nil || tvos != nil, "MultiPlatform empty can't be rendered")

        return .functionCall(name: "select", arguments: [.basic((
            ios.map { [":iosCase": $0] } <>
            osx.map { [":osxCase": $0] } <>
            watchos.map { [":watchosCase": $0] } <>
            tvos.map { [":tvosCase": $0] } <>
            ["//conditions:default": T.empty] ?? [:]
        ).toSkylark())])
    }
}

struct AttrSet<T: Monoid & SkylarkConvertible & EmptyAwareness>: Monoid, SkylarkConvertible, EmptyAwareness {
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
