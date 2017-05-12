//
//  PodSpec.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
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
    case publicHeaders = "public_headers"
    case compilerFlags = "compiler_flags"
    case libraries
    case dependencies
    case resourceBundles = "resource_bundles"
    case resources = "resources"
    case subspecs
    case source
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
}

protocol PodSpecRepresentable {
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
}

public struct PodSpec: PodSpecRepresentable {
    let name: String
    let sourceFiles: [String]
    let excludeFiles: [String]
    let frameworks: [String]
    let weakFrameworks: [String]
    let subspecs: [PodSpec]
    let dependencies: [String]
    let compilerFlags: [String]
    let source: PodSpecSource?
    let libraries: [String]

    let headerDirectory: String?
    let moduleName: String?

    let publicHeaders: [String]

    let vendoredFrameworks: [String]
    let vendoredLibraries: [String]

    // TODO: Support resource / resources properties as well
    let resourceBundles: [String: [String]]
    let resources: [String]

    let podTargetXcconfig: [String: String]?
    let userTargetXcconfig: [String: String]?
    let xcconfig: [String: String]?

    let ios: PodSpecRepresentable?
    let osx: PodSpecRepresentable?
    let tvos: PodSpecRepresentable?
    let watchos: PodSpecRepresentable?

    let prepareCommand = ""

    public init(JSONPodspec: JSONDict) throws {

        let fieldMap: [PodSpecField: Any] = Dictionary(tuples: JSONPodspec.flatMap { k, v in
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
        compilerFlags = strings(fromJSON: fieldMap[.compilerFlags])
        libraries = strings(fromJSON: fieldMap[.libraries])

        vendoredFrameworks = strings(fromJSON: fieldMap[.vendoredFrameworks])
        vendoredLibraries = strings(fromJSON: fieldMap[.vendoredLibraries])

        headerDirectory = fieldMap[.headerDirectory] as? String
        moduleName = fieldMap[.moduleName] as? String

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

        xcconfig = try? ExtractValue(fromJSON: fieldMap[.xcconfig])
        podTargetXcconfig = try? ExtractValue(fromJSON: fieldMap[.podTargetXcconfig])
        userTargetXcconfig = try? ExtractValue(fromJSON: fieldMap[.userTargetXcconfig])

        ios = (fieldMap[.ios] as? JSONDict).flatMap { try? PodSpec(JSONPodspec: $0) }
        osx = (fieldMap[.osx] as? JSONDict).flatMap { try? PodSpec(JSONPodspec: $0) }
        tvos = (fieldMap[.tvos] as? JSONDict).flatMap { try? PodSpec(JSONPodspec: $0) }
        watchos = (fieldMap[.watchos] as? JSONDict).flatMap { try? PodSpec(JSONPodspec: $0) }
    }
}


indirect enum ComposedSpec {
  case composed(child: PodSpec, parent: ComposedSpec?)

    var child: PodSpec {
        switch self {
        case .composed(let child, _): return child
        }
    }

    var parent: ComposedSpec? {
        switch self {
        case .composed(_, let parent): return parent
        }
    }

    static func create(fromSpecs specs: [PodSpec]) -> ComposedSpec {
        guard let parentSpec = specs.first else {
            fatalError("ComposedSpec.create requires at least one element")
        }

        return specs.dropFirst().flatMap { $0 }
            .reduce(.composed(child: parentSpec, parent: nil)) { (parent, child) in
                    .composed(child: child, parent: parent)
        }
    }
}

extension ComposedSpec {
    enum lens {
        static let child: Lens<ComposedSpec, PodSpec> = {
            return ReadonlyLens{ $0.child }
        }()

        static let parent: Lens<ComposedSpec, ComposedSpec?> = {
            return ReadonlyLens{ $0.parent }
        }()

        static func fallback<E: EmptyAwareness & Monoid>(_ lens: Lens<PodSpec, E>) -> Lens<ComposedSpec, E> {
            return ReadonlyLens{ mostChildSpec in
                func loop(_ currentParent: Lens<ComposedSpec, ComposedSpec?>) -> E {
                    let childValue: E? = mostChildSpec ^* (currentParent >•> liftOpt(ComposedSpec.lens.child) >•> liftOpt(lens))
                    if let childValue = childValue {
                        return childValue.isEmpty ? loop(currentParent >•> ComposedSpec.lens.parent) : childValue
                    } else {
                        return childValue.denormalize()
                    }
                }
                return loop(liftOpt(identityLens()))
            }
        }
    }
}


extension PodSpec {
    enum lens {

        static let name: Lens<PodSpecRepresentable, String> = {
            ReadonlyLens { $0.name }
        }()

        static let sourceFiles: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.sourceFiles }
        }()
        static let excludeFiles: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.excludeFiles }
        }()
        static let frameworks: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.frameworks }
        }()
        static let weakFrameworks: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.weakFrameworks }
        }()
        static let subspecs: Lens<PodSpecRepresentable, [PodSpec]> = {
            ReadonlyLens { $0.subspecs }
        }()
        static let dependencies: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.dependencies }
        }()
        static let compilerFlags: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.compilerFlags }
        }()
        static let source: Lens<PodSpecRepresentable, PodSpecSource?> = {
            ReadonlyLens { $0.source }
        }()
        static let libraries: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.libraries }
        }()
        static let resourceBundles: Lens<PodSpecRepresentable, [String: [String]]> = {
            ReadonlyLens { $0.resourceBundles }
        }()

        static let resources: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.resources }
        }()

        static let ios: Lens<PodSpec, PodSpecRepresentable?> = {
            ReadonlyLens { $0.ios }
        }()
        static let osx: Lens<PodSpec, PodSpecRepresentable?> = {
            ReadonlyLens { $0.osx }
        }()
        static let tvos: Lens<PodSpec, PodSpecRepresentable?> = {
            ReadonlyLens { $0.tvos }
        }()
        static let watchos: Lens<PodSpec, PodSpecRepresentable?> = {
            ReadonlyLens { $0.watchos }
        }()

        static let vendoredLibraries: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.vendoredLibraries }
        }()

        static let vendoredFrameworks: Lens<PodSpecRepresentable, [String]> = {
            ReadonlyLens { $0.vendoredFrameworks }
        }()

        static let headerDirectory: Lens<PodSpecRepresentable, String?> = {
            ReadonlyLens { $0.headerDirectory }
        }()

        static let moduleName: Lens<PodSpecRepresentable, String?> = {
            ReadonlyLens { $0.moduleName }
        }()

        static let podTargetXcconfig: Lens<PodSpecRepresentable, [String: String]?> = {
             ReadonlyLens { $0.podTargetXcconfig }
        }()

        static let userTargetXcconfig: Lens<PodSpecRepresentable, [String: String]?>  = {
             ReadonlyLens { $0.userTargetXcconfig }
        }()

        static let xcconfig: Lens<PodSpecRepresentable, [String: String]?>  = {
             ReadonlyLens { $0.xcconfig }
        }()

        static func liftOntoPodSpec<Part>(_ lens: Lens<PodSpecRepresentable, Part>) -> Lens<PodSpec, Part> {
            return ReadonlyLens { (repr: PodSpec) -> Part in
                (repr as PodSpecRepresentable) ^* lens
            }
        }

        static func liftOntoSubspecs<Part: Semigroup>(_ lens: Lens<PodSpec, Part?>) -> Lens<PodSpec, Part?> {
            return ReadonlyLens { whole in
                (whole ^* lens) <+> sfold(whole.subspecs.map{ $0 ^* lens })
            }
        }
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

