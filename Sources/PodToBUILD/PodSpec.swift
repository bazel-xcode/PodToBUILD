//
//  PodSpec.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation

/*
 Cocoapods Podspec Specification (as of 4/25/17)
 https://guides.cocoapods.org/syntax/podspec.html#specification

 Root Specification:
 name R
 version R
 cocoapods_version
 authors R
 social_media_url
 license R
 homepage R
 source R
 summary R
 description
 screenshots
 documentation_url
 prepare_command
 deprecated
 deprecated_in_favor_of
 A ‘root’ specification stores the information about the specific version of a library.
 The attributes in this group can only be written to on the ‘root’ specification, not on the ‘sub-specifications’.

 ---

 Platform:
 platform
 deployment_target

 A specification should indicate the platform and the correspondent deployment targets on which the library is supported. If not defined in a subspec the attributes of this group inherit the value of the parent."

 ---

 Build settings:
 dependency
 requires_arc M
 frameworks M
 weak_frameworks M
 libraries M
 compiler_flags M
 pod_target_xcconfig M
 user_target_xcconfig M
 prefix_header_contents M
 prefix_header_file M
 module_name
 header_dir M
 header_mappings_dir M

 ---
 File Patterns (Glob-able) - All MultiPlatform
 source_files
 public_header_files
 private_header_files
 vendored_frameworks
 vendored_libraries
 resource_bundles
 resources
 exclude_files
 preserve_paths
 module_map

 ---

 Subspecs:
 subspec
 default_subspecs

 On one side, a specification automatically inherits as a dependency all it children ‘sub-specifications’ (unless a default subspec is specified).
 On the other side, a ‘sub-specification’ inherits the value of the attributes of the parents so common values for attributes can be specified in the ancestors.

 ---

 Multi-Platform support:
 ios
 osx
 tvos
 watchos

 A specification can store values which are specific to only one platform.
 For example one might want to store resources which are specific to only iOS projects.
 spec.resources = 'Resources /**/ *.png'
 spec.ios.resources = 'Resources_ios /**/ *.png'

 */

public enum PodSpecField: String {
    case name
    case frameworks
    case weakFrameworks = "weak_frameworks"
    case excludeFiles = "exclude_files"
    case sourceFiles = "source_files"
    case publicHeaders = "public_header_files"
    case privateHeaders = "private_header_files"
    case preservePaths = "preserve_paths"
    case compilerFlags = "compiler_flags"
    case libraries
    case dependencies
    case resourceBundles = "resource_bundles"
    case resources = "resources"
    case subspecs
    case source
    case license
    case podTargetXcconfig = "pod_target_xcconfig"
    case userTargetXcconfig = "user_target_xcconfig"
    case xcconfig // Legacy
    case ios
    case osx
    case tvos
    case watchos
    case vendoredFrameworks = "vendored_frameworks"
    case vendoredLibraries = "vendored_libraries"
    case moduleName = "module_name"
    case headerDirectory = "header_dir"
    case requiresArc = "requires_arc"
    case defaultSubspecs = "default_subspecs"
}

public protocol PodSpecRepresentable {
    var name: String { get }
    var podTargetXcconfig: [String: String]? { get }
    var userTargetXcconfig: [String: String]? { get }
    var sourceFiles: [String] { get }
    var excludeFiles: [String] { get }
    var frameworks: [String] { get }
    var weakFrameworks: [String] { get }
    var subspecs: [PodSpec] { get }
    var dependencies: [String] { get }
    var compilerFlags: [String] { get }
    var source: PodSpecSource? { get }
    var libraries: [String] { get }
    var resourceBundles: [String: [String]] { get }
    var resources: [String] { get }
    var vendoredFrameworks: [String] { get }
    var vendoredLibraries: [String] { get }
    var headerDirectory: String? { get }
    var xcconfig: [String: String]? { get }
    var moduleName: String? { get }
    var requiresArc: Either<Bool, [String]>? { get }
    var publicHeaders: [String] { get }
    var privateHeaders: [String] { get }
    var preservePaths: [String] { get }
    var defaultSubspecs: [String] { get }
}

public typealias PodSpecAttr = PodSpecRepresentable

public struct PodSpec: PodSpecRepresentable {
    public let name: String
    public let sourceFiles: [String]
    public let excludeFiles: [String]
    public let frameworks: [String]
    public let weakFrameworks: [String]
    public let subspecs: [PodSpec]
    public let dependencies: [String]
    public let compilerFlags: [String]
    public let source: PodSpecSource?
    public let license: PodSpecLicense
    public let libraries: [String]
    public let defaultSubspecs: [String]

    public let headerDirectory: String?
    public let moduleName: String?
    // requiresArc can be a bool
    // or it could be a list of pattern
    // or it could be omitted (in which case we need to fallback)
    public let requiresArc: Either<Bool, [String]>?

    public let publicHeaders: [String]
    public let privateHeaders: [String]
    public let preservePaths: [String]

    public let vendoredFrameworks: [String]
    public let vendoredLibraries: [String]

    // TODO: Support resource / resources properties as well
    public let resourceBundles: [String: [String]]
    public let resources: [String]

    public let podTargetXcconfig: [String: String]?
    public let userTargetXcconfig: [String: String]?
    public let xcconfig: [String: String]?

    public let ios: PodSpecRepresentable?
    public let osx: PodSpecRepresentable?
    public let tvos: PodSpecRepresentable?
    public let watchos: PodSpecRepresentable?

    public let prepareCommand = ""

    public init(JSONPodspec: JSONDict) throws {

        let fieldMap: [PodSpecField: Any] = Dictionary(tuples: JSONPodspec.compactMap { k, v in
            guard let field = PodSpecField.init(rawValue: k) else {
                fputs("WARNING: Unsupported field in Podspec \(k)\n", __stderrp)
                return nil
            }
            return .some((field, v))
        })

        if let name = try? ExtractValue(fromJSON: fieldMap[.name]) as String {
            self.name = name
        } else {
            // This is for "ios", "macos", etc
            name = ""
        }
        frameworks = strings(fromJSON: fieldMap[.frameworks])
        weakFrameworks = strings(fromJSON: fieldMap[.weakFrameworks])
        excludeFiles = strings(fromJSON: fieldMap[.excludeFiles])
        sourceFiles = strings(fromJSON: fieldMap[.sourceFiles])
        publicHeaders = strings(fromJSON: fieldMap[.publicHeaders])
        privateHeaders = strings(fromJSON: fieldMap[.privateHeaders])
        preservePaths = strings(fromJSON: fieldMap[.preservePaths])
        compilerFlags = strings(fromJSON: fieldMap[.compilerFlags])
        libraries = strings(fromJSON: fieldMap[.libraries])

        defaultSubspecs = strings(fromJSON: fieldMap[.defaultSubspecs])

        vendoredFrameworks = strings(fromJSON: fieldMap[.vendoredFrameworks])
        vendoredLibraries = strings(fromJSON: fieldMap[.vendoredLibraries])

        headerDirectory = fieldMap[.headerDirectory] as? String
        moduleName = fieldMap[.moduleName] as? String
        requiresArc = (fieldMap[.requiresArc] as? Bool).map{ .left($0) } ?? // try a bool
	        stringsStrict(fromJSON: fieldMap[.requiresArc]).map{ .right($0) } // try a string

        if let podSubspecDependencies = fieldMap[.dependencies] as? JSONDict {
            dependencies = Array(podSubspecDependencies.keys)
        } else {
            dependencies = []
        }

        if let resourceBundleMap = fieldMap[.resourceBundles] as? JSONDict {
            resourceBundles = Dictionary(tuples: resourceBundleMap.map { key, val in
                (key, strings(fromJSON: val))
            })
        } else {
            resourceBundles = [:]
        }

        resources = strings(fromJSON: fieldMap[.resources])

        if let JSONPodSubspecs = fieldMap[.subspecs] as? [JSONDict] {
            subspecs = try JSONPodSubspecs.map { try PodSpec(JSONPodspec: $0) }
        } else {
            subspecs = []
        }

        if let JSONSource = fieldMap[.source] as? JSONDict {
            source = PodSpecSource.source(fromDict: JSONSource)
        } else {
            source = nil
        }

        license = PodSpecLicense.license(fromJSON: fieldMap[.license])

        xcconfig = try? ExtractValue(fromJSON: fieldMap[.xcconfig])
        podTargetXcconfig = try? ExtractValue(fromJSON: fieldMap[.podTargetXcconfig])
        userTargetXcconfig = try? ExtractValue(fromJSON: fieldMap[.userTargetXcconfig])

        ios = (fieldMap[.ios] as? JSONDict).flatMap { try? PodSpec(JSONPodspec: $0) }
        osx = (fieldMap[.osx] as? JSONDict).flatMap { try? PodSpec(JSONPodspec: $0) }
        tvos = (fieldMap[.tvos] as? JSONDict).flatMap { try? PodSpec(JSONPodspec: $0) }
        watchos = (fieldMap[.watchos] as? JSONDict).flatMap { try? PodSpec(JSONPodspec: $0) }
    }
}

public struct FallbackSpec {
    let specs: [PodSpec]
    // Takes the first non empty value
    public func attr<T>(_ keyPath: KeyPath<PodSpecRepresentable, T>) -> AttrSet<T> {
        for spec in specs {
            let value = spec.attr(keyPath)
            if !value.isEmpty {
                return value
            }
        }
        return AttrSet.empty
    }
}

// The source component of a PodSpec
// @note currently only git is supported
public enum PodSpecSource {
    case git(url: URL, tag: String?, commit: String?)
    case http(url: URL)

    static func source(fromDict dict: JSONDict) -> PodSpecSource {
        if let gitURLString: String = try? ExtractValue(fromJSON: dict["git"])  {
            guard let gitURL = URL(string: gitURLString) else {
                fatalError("Invalid source URL for Git: \(gitURLString)")
            }
            let tag: String? = try? ExtractValue(fromJSON: dict["tag"])
            let commit: String? = try? ExtractValue(fromJSON: dict["commit"])
            return .git(url: gitURL, tag: tag, commit: commit)
        } else if let httpURLString: String = try? ExtractValue(fromJSON: dict["http"]) {
            guard let httpURL = URL(string: httpURLString) else {
                fatalError("Invalid source URL for HTTP: \(httpURLString)")
            }
            return .http(url: httpURL)
        } else {
            fatalError("Unsupported source for PodSpec - \(dict)")
        }
    }
}

public struct PodSpecLicense {
    /// The type of the license.
    /// @note it's primarily used for the UI
    public let type: String?

    /// A license can either be a file or a text license
    /// If there is no explict license, the LICENSE(.*) is implicitly
    /// used
    public let text: String?
    public let file: String?

    public static func license(fromJSON value: Any?) -> PodSpecLicense {
        if let licenseJSON = value as? JSONDict {
            return PodSpecLicense(
                    type: try? ExtractValue(fromJSON: licenseJSON["type"]),
                    text: try? ExtractValue(fromJSON: licenseJSON["text"]),
                    file: try? ExtractValue(fromJSON: licenseJSON["file"])
                    )
        }
        if let licenseString = value as? String {
            return PodSpecLicense(type: licenseString, text: nil, file: nil)
        }
        return PodSpecLicense(type: nil, text: nil, file: nil)
    }
}

// MARK: - JSON Value Extraction

public typealias JSONDict = [String: Any]

public enum JSONError: Error {
    case unexpectedValueError
}

public func ExtractValue<T>(fromJSON JSON: Any?) throws -> T {
    if let value = JSON as? T {
        return value
    }
    throw JSONError.unexpectedValueError
}

// Pods intermixes arrays and strings all over
// Coerce to a more sane type, since we don't care about the
// original input
fileprivate func strings(fromJSON JSONValue: Any? = nil) -> [String] {
    if let str = JSONValue as? String {
        return [str]
    }
    if let array = JSONValue as? [String] {
        return array
    }
    return [String]()
}

fileprivate func stringsStrict(fromJSON JSONValue: Any? = nil) -> [String]? {
    if let str = JSONValue as? String {
        return [str]
    }
    if let array = JSONValue as? [String] {
        return array
    }
    return nil
}

