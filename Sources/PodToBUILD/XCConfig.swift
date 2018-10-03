//
//  XCConfig.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/27/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//
// Notes:
// Clang uses the right most value for a given flag
// EX:
// clang  S/main.m -Wmacro-redefined
// -Wno-macro-redefined -framework Foundation -DDEBUGG=0 -DDEBUGG=1 -o e
//
// Here the compiler will not emit the warning, since we passed -Wno
// after the -W option was passed

import Foundation

public protocol XCConfigValueTransformer {
    func string(forXCConfigValue value: String) -> String?
    var xcconfigKey: String { get }
}

enum XCConfigValueTransformerError: Error {
    case unimplemented
}

public struct XCConfigTransformer {
    private let registry: [String: XCConfigValueTransformer]

    init(transformers: [XCConfigValueTransformer]) {
        var registry = [String: XCConfigValueTransformer]()
        transformers.forEach { registry[$0.xcconfigKey] = $0 }
        self.registry = registry
    }

    func compilerFlag(forXCConfigKey key: String, XCConfigValue value: String) throws -> [String] {
        // Case insensitve?
        guard let transformer = registry[key] else {
            throw XCConfigValueTransformerError.unimplemented
        }

        let allValues = value.components(separatedBy: CharacterSet.whitespaces)
        return allValues.filter { $0 != "$(inherited)" }
            .compactMap { val in
                return transformer.string(forXCConfigValue: val)?
                    .replacingOccurrences(of: "$(PODS_ROOT)", with: "Vendor")
                    .replacingOccurrences(of: "$(PODS_TARGET_SRCROOT)", with: "Vendor")
            }
    }

    public static func defaultTransformer(externalName: String, sourceType: BazelSourceLibType) -> XCConfigTransformer {
        return XCConfigTransformer(transformers: [
            PassthroughTransformer(xcconfigKey: "OTHER_CFLAGS"),
            PassthroughTransformer(xcconfigKey: "OTHER_LDFLAGS"),
            PassthroughTransformer(xcconfigKey: "OTHER_CPLUSPLUSFLAGS"),
            HeaderSearchPathTransformer(externalName: externalName),
            CXXLibraryTransformer(enabled: sourceType == .cpp),
            CXXLanguageStandardTransformer(enabled: sourceType == .cpp),
            PreprocessorDefinesTransformer(),
            AllowNonModularIncludesInFrameworkModulesTransformer(),
            PreCompilePrefixHeaderTransformer(),
        ])
    }

    public func compilerFlags(forXCConfig xcconfig: [String: String]?) -> [String] {
        if let xcconfig = xcconfig {
            return xcconfig.compactMap { try? compilerFlag(forXCConfigKey: $0, XCConfigValue: $1) }
                .flatMap { $0 }
        }
        return [String]()
    }
}

//  MARK: - Value Transformers

// public struct for creating transformers instances that simply return their values
public struct PassthroughTransformer: XCConfigValueTransformer {
    private let key: String

    public var xcconfigKey: String {
        return self.key
    }

    init(xcconfigKey: String) {
        self.key = xcconfigKey
    }

    public func string(forXCConfigValue value: String) -> String? {
        return value
    }
}

public struct PreCompilePrefixHeaderTransformer: XCConfigValueTransformer {
    public var xcconfigKey: String {
        return "GCC_PRECOMPILE_PREFIX_HEADER"
    }

    public func string(forXCConfigValue _: String) -> String? {
        // TODO: Implement precompiled header support in Bazel.
        return ""
    }
}

public struct HeaderSearchPathTransformer: XCConfigValueTransformer {
    public static let xcconfigKey = "HEADER_SEARCH_PATHS"
    public var xcconfigKey: String = HeaderSearchPathTransformer.xcconfigKey
    
    let externalName: String
    init(externalName: String) {
        self.externalName = externalName;
    }
    
    public func string(forXCConfigValue value: String) -> String? {
        let cleaned = value.replacingOccurrences(of: "$(PODS_TARGET_SRCROOT)",
            with: "Vendor/\(externalName)").replacingOccurrences(of: "\"", with: "")
        return "-I\(cleaned)"
    }
}

public struct PreprocessorDefinesTransformer: XCConfigValueTransformer {
    public var xcconfigKey: String {
        return "GCC_PREPROCESSOR_DEFINITIONS"
    }

    public func string(forXCConfigValue value: String) -> String? {
        return "-D\(value)"
    }
}

public struct AllowNonModularIncludesInFrameworkModulesTransformer: XCConfigValueTransformer {
    public var xcconfigKey: String {
        return "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES"
    }

    public func string(forXCConfigValue _: String) -> String? {
        return "-Wno-non-modular-include-in-framework-module -Wno-error=noon-modular-include-in-framework-module"
    }
}

/// MARK - CXX specific settings
/// Don't enable CXX specific settings for C/ObjC libs.
/// It is possible that a user may create such a Podspec.
public struct CXXLanguageStandardTransformer: XCConfigValueTransformer {
    let enabled: Bool

    init(enabled: Bool) {
        self.enabled = enabled
    }

    public var xcconfigKey: String {
        return "CLANG_CXX_LANGUAGE_STANDARD"
    }

    public func string(forXCConfigValue value: String) -> String? {
        guard enabled else {
            return nil
        }
        return "-std=\(value)"
    }
}

public struct CXXLibraryTransformer: XCConfigValueTransformer {
    let enabled: Bool

    init(enabled: Bool) {
        self.enabled = enabled
    }

    public var xcconfigKey: String {
        return "CLANG_CXX_LIBRARY"
    }

    public func string(forXCConfigValue value: String) -> String? {
        guard enabled else {
            return nil
        }
        return "-stdlib=\(value)"
    }
}

