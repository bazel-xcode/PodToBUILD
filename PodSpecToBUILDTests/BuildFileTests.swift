//
//  BuildFileTests.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import XCTest

class BuildFileTests: XCTestCase {
    // MARK: - Transform Tests

    func testWildCardSourceDependentSourceExclusion() {
        let parentLib = ObjcLibrary(name: "Core",
                                    externalName: "Core",
                                    sourceFiles: ["Source/*.m"],
                                    headers: [String](),
                                    sdkFrameworks: AttrSet.empty,
                                    weakSdkFrameworks: AttrSet.empty,
                                    sdkDylibs: AttrSet.empty,
                                    deps: AttrSet.empty,
                                    copts: AttrSet.empty,
                                    bundles: AttrSet.empty,
                                    excludedSource: [String]())

        let depLib = ObjcLibrary(name: "ChildLib",
                                 externalName: "Core",
                                 sourceFiles: ["Source/SomeSource.m"],
                                 headers: [String](),
                                 sdkFrameworks: AttrSet.empty,
                                 weakSdkFrameworks: AttrSet.empty,
                                 sdkDylibs: AttrSet.empty,
                                 deps: AttrSet(basic: [":Core"]),
                                 copts: AttrSet.empty,
                                 bundles: AttrSet.empty,
                                 excludedSource: [String]())
        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(libByName["Core"]!.excludedSource, ["Source/SomeSource.m"])
    }

    func testWildCardDirectoryDependentSourceExclusion() {
        let parentLib = ObjcLibrary(name: "Core",
                                    externalName: "Core",
                                    sourceFiles: ["Source/**/*.m"],
                                    headers: [String](),
                                    sdkFrameworks: AttrSet.empty,
                                    weakSdkFrameworks: AttrSet.empty,
                                    sdkDylibs: AttrSet.empty,
                                    deps: AttrSet.empty,
                                    copts: AttrSet.empty,
                                    bundles: AttrSet.empty,
                                    excludedSource: [String]())

        let depLib = ObjcLibrary(name: "ChildLib",
                                 externalName: "Core",
                                 sourceFiles: ["Source/Some/Source.m"],
                                 headers: [String](),
                                 sdkFrameworks: AttrSet.empty,
                                 weakSdkFrameworks: AttrSet.empty,
                                 sdkDylibs: AttrSet.empty,
                                 deps: AttrSet(basic: [":Core"]),
                                 copts: AttrSet.empty,
                                 bundles: AttrSet.empty,
                                 excludedSource: [String]())
        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(libByName["Core"]!.excludedSource, ["Source/Some/Source.m"])
    }

    func testWildCardSourceDependentSourceExclusionWithExistingExclusing() {
        let parentLib = ObjcLibrary(name: "Core",
                                    externalName: "Core",
                                    sourceFiles: ["Source/*.m"],
                                    headers: [String](),
                                    sdkFrameworks: AttrSet.empty,
                                    weakSdkFrameworks: AttrSet.empty,
                                    sdkDylibs: AttrSet.empty,
                                    deps: AttrSet.empty,
                                    copts: AttrSet.empty,
                                    bundles: AttrSet.empty,
                                    excludedSource: ["Srce/SomeSource.m"])

        let depLib = ObjcLibrary(name: "ChildLib",
                                 externalName: "Core",
                                 sourceFiles: ["Source/SomeSource.m"],
                                 headers: [String](),
                                 sdkFrameworks: AttrSet.empty,
                                 weakSdkFrameworks: AttrSet.empty,
                                 sdkDylibs: AttrSet.empty,
                                 deps: AttrSet(basic: [":Core"]),
                                 copts: AttrSet.empty,
                                 bundles: AttrSet.empty,
                                 excludedSource: [String]())
        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(libByName["ChildLib"]!.excludedSource, [String]())
        XCTAssertEqual(libByName["Core"]!.excludedSource, ["Srce/SomeSource.m", "Source/SomeSource.m"])
    }

    private func executePruneRedundantCompilationTransform(libs: [ObjcLibrary]) -> [String: ObjcLibrary] {
        let opts = BasicBuildOptions(podName: "",
                                     userOptions: [String](),
                                     globalCopts: [String](),
                                     trace: false
                                        )
        let transformed  = RedundantCompiledSourceTransform.transform(convertibles: libs, options: opts)
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
        let lib = ObjcLibrary(rootName: podspec.name, spec: podspec)
        
        let expectedFrameworks: AttrSet<[String]> = AttrSet(multi: MultiPlatform(
            ios: ["UIKit"],
            osx: ["Cocoa"],
            watchos: nil,
            tvos: ["UIKit"]))
        XCTAssert(lib.sdkFrameworks == expectedFrameworks)
    }
    
    func testNameFromPodspec() {
        let podspec = examplePodSpecNamed(name: "IGListKit")
        let lib = ObjcLibrary(rootName: podspec.name, spec: podspec)
        
        XCTAssert(lib.name == podspec.name)
    }
    
    func testDependOnSubspecs() {
        let podspec = examplePodSpecNamed(name: "IGListKit")
        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)
        
        XCTAssert(
            AttrSet(basic: [":IGListKit_Diffing", ":IGListKit_Default"]) ==
                (convs.flatMap{ $0 as? ObjcLibrary}.first!).deps
        )
    }
    
    func testProperlyOutputConfig() {
        let podspec = try! PodSpec(JSONPodspec: [
                "name": "Foo",
                "osx": ["source_files": ["foo"]]
            ])
        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)
        dump(convs.flatMap{ $0 as? ConfigSetting })
        XCTAssert(
            convs.flatMap{ $0 as? ConfigSetting }.map{ $0.name }.first { $0.contains("osx") } != nil
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
            convs.flatMap{ $0 as? ConfigSetting }.map{ $0.name }.first { $0.contains("osx") } != nil
        )
    }
    
    func testDontOutputConfig() {
        let podspec = try! PodSpec(JSONPodspec: [
            "name": "Foo"
        ])
        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)
        
        XCTAssert(
            convs.flatMap{ $0 as? ConfigSetting }.count == 0
        )
    }
    
    // MARK: - Source File Extraction Tests

    func testHeaderExtraction() {
        let podPattern = "Source/Classes/**/*.{h,m}"
        let headersAndSourcesInfo = headersAndSources(fromSourceFilePatterns: [podPattern])
        XCTAssertEqual(headersAndSourcesInfo.headers, ["Source/Classes/**/*.h"])
        XCTAssertEqual(headersAndSourcesInfo.sourceFiles, ["Source/Classes/**/*.m"])
    }

    func testHeaderExtractionWithBarPattern() {
        let podPattern = "Source/Classes/**/*.[h,m]"
        let headersAndSourcesInfo = headersAndSources(fromSourceFilePatterns: [podPattern])
        XCTAssertEqual(headersAndSourcesInfo.headers, ["Source/Classes/**/*.h"])
        XCTAssertEqual(headersAndSourcesInfo.sourceFiles, ["Source/Classes/**/*.m"])
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
        let compilerFlags = XCConfigTransformer.defaultTransformer().compilerFlags(forXCConfig: config)
        XCTAssertEqual(compilerFlags, ["-DGPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1"])
    }

    func testCXXXCConfigs() {
        let config = [
            "CLANG_CXX_LANGUAGE_STANDARD": "c++11",
            "CLANG_CXX_LIBRARY": "libc++",
        ]
        let compilerFlags = XCConfigTransformer.defaultTransformer().compilerFlags(forXCConfig: config)
        XCTAssertEqual(compilerFlags, ["-stdlib=c++11", "-stdlib=libc++"])
    }
}
