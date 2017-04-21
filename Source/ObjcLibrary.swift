//
//  ObjcLibrary.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/19/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

// ObjcLibrary is an intermediate rep of an objc library
struct ObjcLibrary: SkylarkConvertible {
    var name: String
    var sourceFiles: [String]
    var headers: [String]
    var sdkFrameworks: [String]
    var sdkDylibs: [String]
    var deps: [String]
    var copts: [String]
    var excludedSource = [String]()

    // MARK: - Bazel Rendering

    func toSkylark() -> [SkylarkNode] {
        let lib = self
        let nameArgument = SkylarkFunctionArgument.named(name: "name", value: .string(value: lib.name))

        var inlineSkylark = [SkylarkNode]()
        var libArguments = [SkylarkFunctionArgument]()

        libArguments.append(nameArgument)
        if lib.sourceFiles.count > 0 {
            // Glob all of the source files and exclude excluded sources
            var globArguments = [SkylarkFunctionArgument.basic(value: .list(value: lib.sourceFiles.map { .string(value: $0) }))]
            if lib.excludedSource.count > 0 {
                globArguments.append(.named(
                    name: "exclude",
                    value: .list(value: excludedSource.map { .string(value: $0) }
                    )
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
                arguments: [.basic(value: .list(value: lib.headers.map { .string(value: $0) }))]
            ))

            // HACK! There is no assignment in Skylark Imp
            inlineSkylark.append(.functionCall(
                name: "\(lib.name)_extra_headers = glob",
                arguments: [.basic(value: .list(value: [.string(value: "bazel_support/Headers/Public/**/*.h")]))]
            ))

            inlineSkylark.append(.skylark(
                value: "\(lib.name)_headers = \(lib.name)_source_headers + \(lib.name)_extra_headers"
            ))

            libArguments.append(.named(
                name: "hdrs",
                value: .skylark(value: "\(lib.name)_headers")
            ))

            // Include the public headers which are symlinked in
            // All includes are bubbled up automatically
            libArguments.append(.named(
                name: "includes",
                value: .list(value: [
                    .string(value: "bazel_support/Headers/Public/")
                ])
            ))
        }
        if lib.sdkFrameworks.count > 0 {
            libArguments.append(.named(
                name: "sdk_frameworks",
                value: .list(value: lib.sdkFrameworks.map { .string(value: $0) })
            ))
        }
        if lib.sdkDylibs.count > 0 {
            libArguments.append(.named(
                name: "sdk_dylibs",
                value: .list(value: lib.sdkDylibs.map{ .string(value: $0) })
            ))
        }
        if lib.deps.count > 0 {
            libArguments.append(.named(
                name: "deps",
                value: .list(value: lib.deps.map { .string(value: $0) })
            ))
        }
        if lib.copts.count > 0 {
            libArguments.append(.named(
                name: "copts",
                value: .list(value: lib.copts.map { .string(value: $0) })
            ))
        }
        libArguments.append(.named(
            name: "visibility",
            value: .list(value: [.string(value: "//visibility:public")])
        ))
        return inlineSkylark + [.functionCall(name: "objc_library", arguments: libArguments)]
    }
}
