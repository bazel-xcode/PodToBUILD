//
//  UserConfigurable.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 5/2/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

public struct UserConfigurableTargetAttributes {
    let keyPathOperators: [String]

    init(keyPathOperators: [String]) {
        self.keyPathOperators = keyPathOperators
    }

    init (buildOptions: BuildOptions) {
        // User options available are keypath operators
        keyPathOperators = buildOptions.userOptions
    }
}

/// Support a collection of operators
enum UserConfigurableOpt : String {
   /// Add values to a value
   /// EX: "Some.copts += -foo, -bar"
   case PlusEqual = "+="
}

protocol UserConfigurable {
    var name : String { get }

    /// Add a given value to a key
    mutating func add(configurableKey: String, value: Any)

    /// Apply options.
    /// This shouldn't be implemented in consumers
    func apply(keyPathOperators: [String], copts: [String]) -> Self
}

extension UserConfigurable {
    func apply(keyPathOperators: [String], copts: [String]) -> Self {
        var copy = self
        // First, apply all of the global options
        copts.forEach { copy.add(configurableKey: "copts", value: $0) }
        // Explicit keyPathOperators override defaults
        // Since in LLVM option parsing, the rightmost option wins
        // https://clang.llvm.org/doxygen/classclang_1_1tooling_1_1CommonOptionsParser.html
        for keyPathOperator in keyPathOperators {
            guard let opt = UserConfigurableOpt(rawValue: "+=") else {
                print("Invalid operator")
                fatalError()
            }

            var components = keyPathOperator.components(separatedBy: opt.rawValue)
            guard components.count > 1 else { continue }

            let key = components[0].replacingOccurrences(of: " ", with: "")
            let values = components[1].components(separatedBy: ",")
            for value in values {
                let value = value.replacingOccurrences(of: " ", with: "")
                copy.add(configurableKey: key, value: value)
            }
        }
        return copy
    }
}

enum UserConfigurableTransform : SkylarkConvertibleTransform {
    public static func transform(convertibles: [SkylarkConvertible], options: BuildOptions, podSpec: PodSpec) -> [SkylarkConvertible] {
        let attributes = UserConfigurableTargetAttributes(buildOptions: options)
        return UserConfigurableTransform.executeUserOptionsTransform(onConvertibles: convertibles, copts: options.globalCopts, userAttributes: attributes)
    }

    public static  func executeUserOptionsTransform(onConvertibles convertibles: [SkylarkConvertible], copts: [String], userAttributes: UserConfigurableTargetAttributes) -> [SkylarkConvertible] {
        var operatorByTarget = [String: [String]]()
        for keyPath in userAttributes.keyPathOperators {
            let components = keyPath.components(separatedBy: ".")
            if let target = components.first {
                var oprs = (operatorByTarget[target] ?? [String]())
                oprs.append(components[1])
                operatorByTarget[target] = oprs
            }
        }

        let output: [SkylarkConvertible] = convertibles.map {
            (inputConvertible: SkylarkConvertible) in
            guard let configurable = inputConvertible as? UserConfigurable else {
                return inputConvertible
            }

            if let operators = operatorByTarget[configurable.name] {
                return configurable.apply(keyPathOperators: operators, copts: copts) as! SkylarkConvertible
            } else {
                return configurable.apply(keyPathOperators: [], copts: copts) as! SkylarkConvertible
            }
        }
        return output
    }
}
