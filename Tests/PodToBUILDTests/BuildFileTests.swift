//
//  BuildFileTests.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import XCTest
@testable import PodToBUILD

class BuildFileTests: XCTestCase {
    // MARK: - Transform Tests

    func lib(name: String, externalName: String) -> ObjcLibrary {
	    return ObjcLibrary(name: name,
                    externalName: externalName,
                    sourceFiles: GlobNode.empty,
                    headers: GlobNode.empty,
                    headerName: AttrSet(basic: externalName),
                    includes: [],
                    sdkFrameworks: AttrSet.empty,
                    weakSdkFrameworks: AttrSet.empty,
                    sdkDylibs: AttrSet.empty,
                    deps: AttrSet.empty,
                    copts: AttrSet.empty,
                    bundles: AttrSet.empty,
                    resources: GlobNode.empty,
                    publicHeaders: AttrSet.empty,
			        nonArcSrcs: GlobNode.empty,
			        requiresArc: .left(true),
                    isTopLevelTarget: false
        )
    }

    let zoomToInclude: Lens<ObjcLibrary, AttrSet<Set<String>>> =
        ObjcLibrary.lens.sourceFiles ..
                GlobNode.lens.include
    let zoomToExclude: Lens<ObjcLibrary, AttrSet<Set<String>>> =
        ObjcLibrary.lens.sourceFiles ..
                GlobNode.lens.exclude

    func testWildCardSourceDependentSourceExclusion() {
        let include: Set<String> = ["Source/*.m"]
        let exclude: Set<String> = ["Source/SomeSource.m"]

        let parentLib: ObjcLibrary = lib(name: "Core", externalName: "Core") |>
            zoomToInclude .. AttrSet<Set<String>>.lens.basic() .~ .some(include)

        let depLib = lib(name: "ChildLib", externalName: "Core") |>
            zoomToInclude .. AttrSet<Set<String>>.lens.basic() .~ .some(exclude) |>
            ObjcLibrary.lens.deps .. AttrSet<[String]>.lens.basic() .~ .some([":Core"])

        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssert(libByName["Core"]!.sourceFiles == GlobNode(
            include: AttrSet(basic: include),
            exclude: AttrSet(basic: exclude)
        ))
    }

    func testWildCardDirectoryDependentSourceExclusion() {
        let include: Set<String> = ["Source/**/*.m"]
        let exclude: Set<String> = ["Source/Some/Source.m"]

        let parentLib: ObjcLibrary = lib(name: "Core", externalName: "Core") |>
            zoomToInclude .. AttrSet<Set<String>>.lens.basic() .~ .some(include)

        let depLib = lib(name: "ChildLib", externalName: "Core") |>
            zoomToInclude .. AttrSet<Set<String>>.lens.basic() .~ .some(exclude) |>
            ObjcLibrary.lens.deps .. AttrSet<[String]>.lens.basic() .~ .some([":Core"])

        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssert(libByName["Core"]!.sourceFiles == GlobNode(
            include: AttrSet(basic: include),
            exclude: AttrSet(basic: exclude)
        ))
    }

    func testWildCardSourceDependentSourceExclusionWithExistingExclusing() {
        let parentLib: ObjcLibrary = lib(name: "Core", externalName: "Core") |>
            zoomToInclude .. AttrSet<Set<String>>.lens.basic() .~ .some(Set(["Source/*.m"])) |>
            zoomToExclude .. AttrSet<Set<String>>.lens.basic() .~ .some(Set(["Srce/SomeSource.m"]))

        let childSourceFiles = GlobNode(
                                    include: AttrSet(basic: Set(["Source/SomeSource.m"])),
                                    exclude: AttrSet.empty
						         )

        let depLib: ObjcLibrary = lib(name: "ChildLib", externalName: "Core") |>
            ObjcLibrary.lens.sourceFiles .~ childSourceFiles |>
            ObjcLibrary.lens.deps .. AttrSet<[String]>.lens.basic() .~ .some([":Core"])

        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(libByName["ChildLib"]!.sourceFiles.include.basic, childSourceFiles.include.basic)
        XCTAssert(libByName["Core"]!.sourceFiles == GlobNode(
            include: AttrSet(basic: Set(["Source/*.m"])),
            exclude: AttrSet(basic: Set(["Srce/SomeSource.m", "Source/SomeSource.m"]))
        ))
    }

    func testWildCardSourceDependentIosExclusion() {
        let parentLib: ObjcLibrary = lib(name: "Core", externalName: "Core") |>
            zoomToInclude ..
            AttrSet<Set<String>>.lens.multi() ..
            MultiPlatform<Set<String>>.lens.ios() .~ .some(["Source/*.m"]) |>
            zoomToExclude .. AttrSet<Set<String>>.lens.basic() .~ .some(["Source/SomeSource.m"])

        let depLib: ObjcLibrary = lib(name: "ChildLib", externalName: "Core") |>
            zoomToInclude ..
            AttrSet<Set<String>>.lens.multi() ..
            MultiPlatform<Set<String>>.lens.ios() .~ .some(["Source/Foo.m"]) |>
            ObjcLibrary.lens.deps .. AttrSet<[String]>.lens.basic() .~ .some([":Core"])

        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssert(libByName["Core"]!.sourceFiles == GlobNode(
            include: AttrSet(multi: MultiPlatform(
                ios: ["Source/*.m"]
            )),
            exclude: AttrSet(basic: ["Source/SomeSource.m"],
                             multi: MultiPlatform(ios: ["Source/Foo.m"]))
        ))
    }

    func testNestedDependentExclusion() {
        let parentLib: ObjcLibrary = lib(name: "Core", externalName: "Core") |>
            zoomToInclude .. AttrSet<Set<String>>.lens.basic() .~ .some(["Source/*.m"])

        let depLib: ObjcLibrary = lib(name: "ChildLib", externalName: "Core") |>
            zoomToInclude .. AttrSet<Set<String>>.lens.basic() .~ .some(["Source/Foo/*.m"]) |>
            ObjcLibrary.lens.deps .. AttrSet<[String]>.lens.basic() .~ .some([":Core"])

        let depDepLib: ObjcLibrary = lib(name: "GrandchildLib", externalName: "Core") |>
            zoomToInclude .. AttrSet<Set<String>>.lens.basic() .~ .some(["Source/Foo/Bar/*.m", "Source/Bar/*.m"]) |>
            ObjcLibrary.lens.deps .. AttrSet<[String]>.lens.basic() .~ .some([":ChildLib"])

        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib, depDepLib])
        XCTAssert(libByName["Core"]!.sourceFiles == GlobNode(
            include: AttrSet(basic: ["Source/*.m"]),
            exclude: AttrSet(basic: ["Source/Bar/*.m", "Source/Foo/*.m", "Source/Foo/Bar/*.m"])
        ))
        XCTAssert(libByName["ChildLib"]!.sourceFiles == GlobNode(
            include: AttrSet(basic: ["Source/Foo/*.m"]),
            exclude: AttrSet(basic: ["Source/Bar/*.m", "Source/Foo/Bar/*.m"])
        ))
    }

    private func executePruneRedundantCompilationTransform(libs: [ObjcLibrary]) -> [String: ObjcLibrary] {
        let opts = BasicBuildOptions(podName: "",
                                     userOptions: [String](),
                                     globalCopts: [String](),
                                     trace: false)
        let transformed = RedundantCompiledSourceTransform.transform(convertibles: libs,
                                                   options: opts,
                                                   podSpec: try! PodSpec(JSONPodspec: JSONDict())
                          )
        var libByName = [String: ObjcLibrary]()
        transformed.forEach {
                let t = ($0 as! ObjcLibrary)
                libByName[t.name] = t
        }
        return libByName
    }

    // MARK: - Multiplatform Tests

    func testLibFromPodspec() {
        let podspec = examplePodSpecNamed(name: "IGListKit")
        let lib = ObjcLibrary(parentSpecs: [], spec: podspec)

        let expectedFrameworks: AttrSet<[String]> = AttrSet(multi: MultiPlatform(
            ios: ["UIKit"],
            osx: ["Cocoa"],
            watchos: nil,
            tvos: ["UIKit"]))
        XCTAssert(lib.sdkFrameworks == expectedFrameworks)
    }

    func testDependOnDefaultSubspecs() {
        let podspec = examplePodSpecNamed(name: "IGListKit")
        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)

        XCTAssert(
            AttrSet(basic: [":Default"]) ==
                (convs.compactMap{ $0 as? ObjcLibrary}.first!).deps
        )
    }

    func testDependOnSubspecs() {
        let podspec = examplePodSpecNamed(name: "PINCache")
        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)

        XCTAssert(
            AttrSet(basic: [":Core", ":Arc-exception-safe"]) ==
                (convs.compactMap{ $0 as? ObjcLibrary}.first!).deps
        )
    }

    func testProperlyOutputConfig() {
        let podspec = try! PodSpec(JSONPodspec: [
                "name": "Foo",
                "osx": ["source_files": ["foo"]]
            ])
        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)
        XCTAssert(
            convs.compactMap{ $0 as? ConfigSetting }.map{ $0.name }.first { $0.contains("osx") } != nil
        )
    }

    func testProperlyOutputConfigSubspecs() {
        let podspec = try! PodSpec(JSONPodspec: [
            "name": "Foo",
            "subspecs": [["name": "Foo_1",
                          "osx": ["source_files": ["foo"]]]]
        ])
        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)
        XCTAssert(
            convs.compactMap{ $0 as? ConfigSetting }.map{ $0.name }.first { $0.contains("osx") } != nil
        )
    }

    // MARK: - Source File Extraction Tests

    func testExtractionCurly() {
        let podPattern = "Source/Classes/**/*.{h,m}"
        let extractedHeaders = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: HeaderFileTypes).basic!
        let extractedSources = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: ObjcLikeFileTypes).basic!
        XCTAssertEqual(extractedHeaders, ["Source/Classes/**/*.h"])
        XCTAssertEqual(extractedSources, ["Source/Classes/**/*.m"])
    }

    func testExtractionWithBarPattern() {
        let podPattern = "Source/Classes/**/*.[h,m]"
        let extractedHeaders = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: HeaderFileTypes).basic!
        let extractedSources = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: ObjcLikeFileTypes).basic!

        XCTAssertEqual(extractedHeaders, ["Source/Classes/**/*.h"])
        XCTAssertEqual(extractedSources, ["Source/Classes/**/*.m"])
    }

    func testExtractionMultiplatform() {
	    let podPattern = "Source/Classes/**/*.[h,m]"
        let extractedHeaders = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: HeaderFileTypes)
        let extractedSources = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: ObjcLikeFileTypes)
        XCTAssert(extractedHeaders == AttrSet(basic: ["Source/Classes/**/*.h"]))
        XCTAssert(extractedSources == AttrSet(basic: ["Source/Classes/**/*.m"]))
    }

    func testHeaderIncExclExtraction() {
        let podSpec = examplePodSpecNamed(name: "PINRemoteImage")
        let library = ObjcLibrary(parentSpecs: [podSpec], spec: podSpec.subspecs.first{ $0.name == "Core" }!)

        ["Source/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.h",
		 "Source/Classes/PINCache/*.h"].forEach{ src in
	        XCTAssert(library.headers.exclude.basic!.contains(src))
        }
		["Source/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.m",
		 "Source/Classes/PINCache/*.m"].forEach{ src in
	        XCTAssert(library.sourceFiles.exclude.basic!.contains(src))
        }
    }

    func testHeaderIncAutoGlob() {
        let podSpec = examplePodSpecNamed(name: "UICollectionViewLeftAlignedLayout")
        let library = ObjcLibrary(parentSpecs: [], spec: podSpec)

        XCTAssert(
            library.headers.include.basic.denormalize().contains("UICollectionViewLeftAlignedLayout/**/*.h")
        )
    }

    // MARK: - JSON Examples

    func testGoogleAPISJSONParsing() {
        let podSpec = examplePodSpecNamed(name: "googleapis")
        XCTAssertEqual(podSpec.name, "googleapis")
        XCTAssertEqual(podSpec.sourceFiles, [String]())
        XCTAssertEqual(podSpec.podTargetXcconfig!, [
            "USER_HEADER_SEARCH_PATHS": "$SRCROOT/..",
            "GCC_PREPROCESSOR_DEFINITIONS": "$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1",
        ]
        )
    }

    func testIGListKitJSONParsing() {
        let podSpec = examplePodSpecNamed(name: "IGListKit")
        XCTAssertEqual(podSpec.name, "IGListKit")
        XCTAssertEqual(podSpec.sourceFiles, [String]())
        XCTAssertEqual(podSpec.podTargetXcconfig!, [
            "CLANG_CXX_LANGUAGE_STANDARD": "c++11",
            "CLANG_CXX_LIBRARY": "libc++",
        ]
        )
    }

    // MARK: - XCConfigs

    func testPreProcesorDefsXCConfigs() {
        // We strip off inherited.
        let config = [
            "USER_HEADER_SEARCH_PATHS": "$SRCROOT/..",
            "GCC_PREPROCESSOR_DEFINITIONS": "$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1",
        ]
        let compilerFlags = XCConfigTransformer
            .defaultTransformer(externalName: "test", sourceType: .objc)
            .compilerFlags(forXCConfig: config)
        XCTAssertEqual(compilerFlags, ["-DGPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1"])
    }

    func testCXXXCConfigs() {
        let config = [
            "CLANG_CXX_LANGUAGE_STANDARD": "c++11",
            "CLANG_CXX_LIBRARY": "libc++",
        ]
        let compilerFlags = XCConfigTransformer
            .defaultTransformer(externalName: "test", sourceType: .cpp)
            .compilerFlags(forXCConfig: config)
        XCTAssertEqual(compilerFlags.sorted(by: (<)), ["-std=c++11", "-stdlib=libc++"])
    }
}
