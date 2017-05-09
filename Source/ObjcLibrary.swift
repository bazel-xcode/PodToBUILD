//
//  ObjcLibrary.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/19/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

/// Law: Names must be valid bazel names; see the spec
protocol BazelTarget: SkylarkConvertible {
    var name: String { get }
}


// https://bazel.build/versions/master/docs/be/objective-c.html#objc_bundle_library
struct ObjcBundleLibrary: BazelTarget {
    let name: String
    let resources: AttrSet<[String]>

    func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "objc_bundle_library",
            arguments: [
                .named(name: "name", value: ObjcLibrary.bazelLabel(fromString: name).toSkylark()),
                .named(name: "resources",
                       value: GlobNode(include: resources,
                                       exclude: AttrSet.empty,
                                       excludeDirectories:true).toSkylark()),
        ])
    }
}

// https://bazel.build/versions/master/docs/be/general.html#config_setting
struct ConfigSetting: BazelTarget {
    let name: String
    let values: [String: String]
    
    func toSkylark() -> SkylarkNode {
        return .functionCall(
            name: "config_setting",
            arguments: [
		        .named(name: "name", value: name.toSkylark()),
		        .named(name: "values", value: values.toSkylark())
            ])
    }
}

/// rootName -> names -> fixedNames
func fixDependencyNames(rootName: String) -> ([String]) -> [String]  {
    return { $0.map { depName in
            // Build up dependencies. Versions are ignored!
            // When a given dependency is locally speced, it should
            // Match the PodName i.e. PINCache/Core
            let results = depName.components(separatedBy: "/")
            if results.count > 1 && results[0] == rootName {
                // This is a local subspec reference
                let join = results[1 ... results.count - 1].joined(separator: "/")
                return ":\(rootName)_\(ObjcLibrary.bazelLabel(fromString: join))"
            } else {
                if results.count > 1, let podname = results.first {
                    // This is a reference to an external podspec's subspec
                    return "@\(podname)//:\(ObjcLibrary.bazelLabel(fromString: depName))"
                } else {
                    // This is a reference to another pod library
                    return "@\(ObjcLibrary.bazelLabel(fromString: depName))//:\(ObjcLibrary.bazelLabel(fromString: depName))"
                }
            }
        }
    }
}

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_framework
struct ObjcFramework: BazelTarget {
    let name: String // A unique name for this rule.
    let frameworkImports: AttrSet<[String]> // The list of files under a .framework directory which are provided to Objective-C targets that depend on this target.


    // objc_framework(
    //     name = "OCMock",
    //     framework_imports = [
    //         glob(["iOS/OCMock.framework/**"]),
    //     ],
    //     is_dynamic = 1,
    //     visibility = ["visibility:public"]
    // )
    func toSkylark() -> SkylarkNode {
        return SkylarkNode.functionCall(
                name: "objc_framework",
                arguments: [
                    .named(name: "name", value: .string(name)),
                    .named(name: "framework_imports",
                           value: GlobNode(include: frameworkImports.map { $0.map { $0 + "/**" } },
                                           exclude: AttrSet.empty,
                                           excludeDirectories:true).toSkylark()),
                    .named(name: "is_dynamic", value: 1),
                    .named(name: "visibility", value: .list(["//visibility:public"]))
                ]
        )
    }
}

// https://bazel.build/versions/master/docs/be/objective-c.html#objc_import
struct ObjcImport: BazelTarget {
    let name: String // A unique name for this rule.
    let archives: AttrSet<[String]> // The list of .a files provided to Objective-C targets that depend on this target.

    func toSkylark() -> SkylarkNode {
        return SkylarkNode.functionCall(
                name: "objc_import",
                arguments: [
                    .named(name: "name", value: name.toSkylark()),
                    .named(name: "archives", value: archives.toSkylark()),
                ]
        )

    }
}

enum ObjcLibraryConfigurableKeys : String {
    case copts
    case sdkFrameworks = "sdk_frameworks"
}

// ObjcLibrary is an intermediate rep of an objc library
struct ObjcLibrary: BazelTarget, UserConfigurable, SourceExcludable {
    let name: String
    let externalName: AttrSet<String>
    let sourceFiles: [String]
    let headers: [String]
    let weakSdkFrameworks: AttrSet<[String]>
    let sdkDylibs: AttrSet<[String]>
    let deps: AttrSet<[String]>
    let bundles: AttrSet<[String]>


    // "var" properties are user configurable so we need mutation here
    var excludedSource = [String]()
    var sdkFrameworks: AttrSet<[String]>
    var copts: AttrSet<[String]>

    static let xcconfigTransformer = XCConfigTransformer.defaultTransformer()

    init(name: String,
        externalName: String,
        sourceFiles: [String],
        headers: [String],
        sdkFrameworks: AttrSet<[String]>,
        weakSdkFrameworks: AttrSet<[String]>,
        sdkDylibs: AttrSet<[String]>,
        deps: AttrSet<[String]>,
        copts: AttrSet<[String]>,
        bundles: AttrSet<[String]>,
        excludedSource: [String] = []) {
        self.name = name
        self.externalName = AttrSet(basic: externalName)
        self.sourceFiles = sourceFiles
        self.headers = headers
        self.sdkFrameworks = sdkFrameworks
        self.weakSdkFrameworks = weakSdkFrameworks
        self.sdkDylibs = sdkDylibs
        self.deps = deps
        self.copts = copts
        self.bundles = bundles
        self.excludedSource = excludedSource
    }

    static func bazelLabel(fromString string: String) -> String {
        return string.replacingOccurrences(of: "/", with: "_")
                     .replacingOccurrences(of: "-", with: "_")
                     .replacingOccurrences(of: "+", with: "_")
    }
    
    init(rootSpec: PodSpec? = nil, spec: PodSpec, extraDeps: [String] = []) {
        let headersAndSourcesInfo = headersAndSources(fromSourceFilePatterns: spec.sourceFiles)
        let fallbackSpec: ComposedSpec = ComposedSpec.create(fromSpecs: [rootSpec, spec].flatMap { $0 })

        let xcconfigFlags =
            ObjcLibrary.xcconfigTransformer.compilerFlags(forXCConfig: (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.podTargetXcconfig)))) +
            ObjcLibrary.xcconfigTransformer.compilerFlags(forXCConfig: (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.userTargetXcconfig)))) +
            ObjcLibrary.xcconfigTransformer.compilerFlags(forXCConfig: (fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.xcconfig))))

        // We are not using the fallback spec here since
        let rootName =  ComposedSpec.create(fromSpecs: [spec, rootSpec].flatMap { $0 }) ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.name))

        self.name = rootSpec == nil ? rootName : ObjcLibrary.bazelLabel(fromString: "\(rootName)_\(spec.name)")

        let moduleName = AttrSet<String>(
            value: fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.moduleName))
        )

        let headerDirectoryName: AttrSet<String?> = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.headerDirectory))

        self.externalName = (moduleName.isEmpty ? nil : moduleName) ??
                            (headerDirectoryName.basic == nil ? nil : headerDirectoryName.denormalize()) ??
                            AttrSet<String>(value: rootName)
        self.sourceFiles = headersAndSourcesInfo.sourceFiles
        self.headers = headersAndSourcesInfo.headers
        self.sdkFrameworks = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.frameworks))
        self.weakSdkFrameworks = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.weakFrameworks))
        self.sdkDylibs = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.libraries))
        self.deps = AttrSet(basic: extraDeps.map{ ":\($0)" }.map(ObjcLibrary.bazelLabel)) <> (spec ^* liftToAttr(PodSpec.lens.dependencies .. ReadonlyLens(fixDependencyNames(rootName: rootName))))
        self.copts = AttrSet(basic: xcconfigFlags) <> (fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.compilerFlags)))
        self.bundles = spec ^* liftToAttr(PodSpec.lens.resourceBundles .. ReadonlyLens { $0.map { k, _ in ":\(spec.name)_Bundle_\(k)" }.map(ObjcLibrary.bazelLabel) })
        self.excludedSource = getCompiledSource(fromPatterns: spec.excludeFiles)
    }

    mutating func add(configurableKey: String, value: Any) {
        if let key = ObjcLibraryConfigurableKeys(rawValue: configurableKey) {
            switch key {
            case .copts:
                if let value = value as? String {
                    self.copts = self.copts <> AttrSet(basic: [value])
                }
            case .sdkFrameworks:
                if let value = value as? String {
                    self.sdkFrameworks = self.sdkFrameworks <> AttrSet(basic: [value])
                }
            }
        }
    }

    // MARK: Source Excludable

    var excludableSourceFiles: [String] {
        return sourceFiles
    }

    mutating func addExcludedSourceFile(sourceFile: String) {
        excludedSource += [sourceFile]
    }

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
                    arguments: [.basic(.string(lib.externalName.basic!))]
                )
            ))

            let headerDirs = lib.externalName.map { "bazel_support/Headers/Public/\($0)/" }
            let headerSearchPaths: Set<String> = headerDirs.fold(basic: { str in Set<String>([str].flatMap { $0 }) },
                                      multi: { (result: Set<String>, multi: MultiPlatform<String>) -> Set<String> in
                                        return result.union([multi.ios, multi.osx, multi.watchos, multi.tvos].flatMap { $0 })
                                    })

            // Include the public headers which are symlinked in
            // All includes are bubbled up automatically
            libArguments.append(.named(
                name: "includes",
                value: (["bazel_support/Headers/Public/"] + headerSearchPaths).toSkylark()
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

// This is domain specific to bazel. Bazel's "glob" can't support wild cards so add
// multiple entries instead of {m, cpp}
// see above for further docs
func getCompiledSource(fromPatterns patterns: [String]) -> [String] {
    var sourceFiles = [String]()
    for sourceFilePattern in patterns {
        if let impl = pattern(fromPattern: sourceFilePattern, includingFileType: "m") {
            sourceFiles.append(impl)
        }
        if let impl = pattern(fromPattern: sourceFilePattern, includingFileType: "mm") {
            sourceFiles.append(impl)
        }
        if let impl = pattern(fromPattern: sourceFilePattern, includingFileType: "cpp") {
            sourceFiles.append(impl)
        }
        if let impl = pattern(fromPattern: sourceFilePattern, includingFileType: "c") {
            sourceFiles.append(impl)
        }
    }
    return sourceFiles
}

typealias SourceFilePatternRep = (headers: [String], sourceFiles: [String])

// Extract Headers and Source Files
// @see getCompiledSource for further docs
func headersAndSources(fromSourceFilePatterns patterns: [String]) -> SourceFilePatternRep {
    var headers = [String]()
    var sourceFiles = [String]()
    for sourceFilePattern in patterns {
        // Optimization: if we're sure about the source extension, skip pattern
        // matching
        if sourceFilePattern.hasSuffix(".h") {
            headers.append(sourceFilePattern)
        } else if sourceFilePattern.hasSuffix(".m") {
            sourceFiles.append(sourceFilePattern)
        } else if sourceFilePattern.hasSuffix(".mm") {
            sourceFiles.append(sourceFilePattern)
        } else if sourceFilePattern.hasSuffix(".c") {
            sourceFiles.append(sourceFilePattern)
        } else if sourceFilePattern.hasSuffix(".cpp") {
            sourceFiles.append(sourceFilePattern)
        } else {
            if let header = pattern(fromPattern: sourceFilePattern, includingFileType: "h") {
                headers.append(header)
            }
            sourceFiles += getCompiledSource(fromPatterns: [sourceFilePattern])
        }
    }
    return (headers, sourceFiles)
}
