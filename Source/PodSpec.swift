//
//  PodSpec.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

struct PodSpec {
    var name: String
    var sourceFiles: [String]
    var excludeFiles: [String]
    var frameworks: [String]
    var weakFrameworks: [String]
    var subspecs: [PodSpec] = []
    var dependencies: [String] = []
    var compilerFlags: [String]
    var source: PodSpecSource?
    var libraries: [String]

    // TODO: None of these fields are parsed. This does *NOT* mean that the
    // program won't build under Bazel.
    var publicHeaders: [String] = []
    var privateHeaders: [String] = []
    var requiresARC: Bool = true

    var xcconfigs: [String: String] = [:]
    var podTargetXcconfig: [String: String] = [:]

    var prepareCommand = ""

    // TODO: Support resource / resources properties as well
    var resourceBundles: [String: [String]] = [:]

    init(JSONPodspec: JSONDict) throws {
        name = try ExtractValue(fromJSON: JSONPodspec["name"])
        frameworks = strings(fromJSON: JSONPodspec["frameworks"])
        weakFrameworks = strings(fromJSON: JSONPodspec["weak_frameworks"])
        excludeFiles = strings(fromJSON: JSONPodspec["exclude_files"])
        sourceFiles = strings(fromJSON: JSONPodspec["source_files"])
        publicHeaders = strings(fromJSON: JSONPodspec["public_headers"])
        compilerFlags = strings(fromJSON: JSONPodspec["compiler_flags"])
        libraries = strings(fromJSON: JSONPodspec["libraries"])
        if let podSubspecDependencies = JSONPodspec["dependencies"] as? JSONDict {
            dependencies = Array(podSubspecDependencies.keys)
        } else {
            dependencies = [String]()
        }

        if let resourceBundleMap = JSONPodspec["resource_bundles"] as? JSONDict {
            resourceBundles = resourceBundleMap.map { key, val in
                return (key, strings(fromJSON: val))
            }.reduce([:], { (dict, tuple) -> [String:[String]] in
                var mutableDict = dict
                mutableDict[tuple.0] = tuple.1
                return mutableDict
            })
        }

        if let JSONPodSubspecs = JSONPodspec["subspecs"] as? [JSONDict] {
            subspecs = try JSONPodSubspecs.map { try PodSpec(JSONPodspec: $0) }
        }

        if let JSONSource = JSONPodspec["source"] as? JSONDict {
            source = try? PodSpecSource(JSONSource: JSONSource)
        }
    }
}

// The source component of a PodSpec
// @note currently only git is supported
struct PodSpecSource {
    var git: String?
    var tag: String?
    var commit: String?

    init(JSONSource: JSONDict) throws {
        git = try ExtractValue(fromJSON: JSONSource["git"])
        tag = try? ExtractValue(fromJSON: JSONSource["tag"])
        commit = try? ExtractValue(fromJSON: JSONSource["commit"])
    }
}

// MARK: - JSON Value Extraction

typealias JSONDict = [String: Any]

enum JSONError: Error {
    case unexpectedValueError
}

func ExtractValue<T>(fromJSON JSON: Any?) throws -> T {
    if let value = JSON as? T {
        return value
    }
    throw JSONError.unexpectedValueError
}

// Pods intermixes arrays and strings all over
// Coerce to a more sane type, since we don't care about the
// original input
private func strings(fromJSON JSONValue: Any? = nil) -> [String] {
    if let str = JSONValue as? String {
        return [str]
    }
    if let array = JSONValue as? [String] {
        return array
    }
    return [String]()
}
