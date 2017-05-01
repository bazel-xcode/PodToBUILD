//
//  ObjcLibrary.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/19/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_bundle_library
struct ObjcBundleLibrary: SkylarkConvertible {
    let name: String
    let resources: [String]

    func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "objc_bundle_library",
            arguments: [
                .named(name: "name", value: .string(name)),
                .named(name: "resources",
                       value: resources.toSkylark()),
        ])
    }
}

// ObjcLibrary is an intermediate rep of an objc library
struct ObjcLibrary: SkylarkConvertible {
    var name: String
    var externalName: String
    var sourceFiles: [String]
    var headers: [String]
    var sdkFrameworks: [String]
    var weakSdkFrameworks: [String]
    var sdkDylibs: AttrSet<[String]>
    var deps: AttrSet<[String]>
    var copts: [String]
    var bundles: [String]
    var excludedSource = [String]()

    // MARK: - Bazel Rendering

    func toSkylark() -> SkylarkNode {
        let lib = self
        let nameArgument = SkylarkFunctionArgument.named(name: "name", value: .string(lib.name))

        var inlineSkylark = [SkylarkNode]()
        var libArguments = [SkylarkFunctionArgument]()

        libArguments.append(nameArgument)
        if lib.sourceFiles.count > 0 {
            // Glob all of the source files and exclude excluded sources
            var globArguments = [SkylarkFunctionArgument.basic(lib.sourceFiles.toSkylark())]
            if lib.excludedSource.count > 0 {
                globArguments.append(.named(
                    name: "exclude",
                    value: excludedSource.toSkylark()
                ))
            }
            libArguments.append(.named(
                name: "srcs",
                value: .functionCall(name: "glob", arguments: globArguments)
            ))
        }

        if lib.headers.count > 0 {
            // Generate header logic
            // source_headers = glob(["Source/*.h"])
            // extra_headers = glob(["bazel_support/Headers/Public/**/*.h"])
            // hdrs = source_headers + extra_headers

            // HACK! There is no assignment in Skylark Imp
            inlineSkylark.append(.functionCall(
                name: "\(lib.name)_source_headers = glob",
                arguments: [.basic(lib.headers.toSkylark())]
            ))

            // HACK! There is no assignment in Skylark Imp
            inlineSkylark.append(.functionCall(
                name: "\(lib.name)_extra_headers = glob",
                arguments: [.basic(["bazel_support/Headers/Public/**/*.h"].toSkylark())]
            ))

            inlineSkylark.append(.skylark(
                "\(lib.name)_headers = \(lib.name)_source_headers + \(lib.name)_extra_headers"
            ))

            libArguments.append(.named(
                name: "hdrs",
                value: .skylark("\(lib.name)_headers")
            ))

             libArguments.append(.named(
                name: "pch",
                value:.functionCall(
                    // Call internal function to find a PCH.
                    // @see workspace.bzl
                    name: "pch_with_name_hint",
                    arguments: [.basic(.string(lib.externalName))]
                )
            ))

            // Include the public headers which are symlinked in
            // All includes are bubbled up automatically
            libArguments.append(.named(
                name: "includes",
                value: [
                    "bazel_support/Headers/Public/",
                    "bazel_support/Headers/Public/\(externalName)/",
                ].toSkylark()
            ))
        }
        if !lib.sdkFrameworks.isEmpty {
            libArguments.append(.named(
                name: "sdk_frameworks",
                value: lib.sdkFrameworks.toSkylark()
            ))
        }

        if !lib.weakSdkFrameworks.isEmpty {
            libArguments.append(.named(
                name: "weak_sdk_frameworks",
                value: lib.weakSdkFrameworks.toSkylark()
            ))
        }

        if !lib.sdkDylibs.isEmpty {
            libArguments.append(.named(
                name: "sdk_dylibs",
                value: lib.sdkDylibs.toSkylark()
            ))
        }

        if !lib.deps.isEmpty {
            libArguments.append(.named(
                name: "deps",
                value: lib.deps.toSkylark()
            ))
        }
        if !lib.copts.isEmpty {
            libArguments.append(.named(
                name: "copts",
                value: lib.copts.toSkylark()
            ))
        }

        if !lib.bundles.isEmpty {
            libArguments.append(.named(name: "bundles",
                                       value: bundles.toSkylark()))
        }
        libArguments.append(.named(
            name: "visibility",
            value: ["//visibility:public"].toSkylark()
        ))
        return .lines(inlineSkylark + [.functionCall(name: "objc_library", arguments: libArguments)])
    }
}
