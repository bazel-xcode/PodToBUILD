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
    func basicGlob(include: Set<String>) -> AttrSet<GlobNode> {
        return AttrSet(basic: GlobNode(include: include))
    }

    // MARK: - Transform Tests
    func testWildCardSourceDependentSourceExclusion() {
        let include: Set<String> = ["Source/*.m"]

        let parentLib = ObjcLibrary(name: "Core", externalName: "Core",
            sourceFiles: basicGlob(include: include))

        let depLib = ObjcLibrary(name: "ChildLib", externalName: "Core",
            sourceFiles: basicGlob(include: include),
            deps: AttrSet(basic: [":Core"]))

        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(
           libByName["Core"]!.sourceFiles,
           AttrSet(basic: GlobNode(
               include: [.left(Set(["Source/*.m"]))],
               exclude: [.right(GlobNode(include: [.left(Set(["Source/*.m"]))]
                   ))])
       ))
    }

    func testWildCardDirectoryDependentSourceExclusion() {
        let include: Set<String> = ["Source/**/*.m"]

        let parentLib = ObjcLibrary(name: "Core", externalName: "Core",
            sourceFiles: basicGlob(include: include))
        let depLib = ObjcLibrary(name: "ChildLib", externalName: "Core",
            sourceFiles: basicGlob(include: include),
            deps: AttrSet(basic: [":Core"]))

        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(
            libByName["Core"]!.sourceFiles, 
            AttrSet(basic: GlobNode(
                include: [.left(Set(["Source/**/*.m"]))],
                exclude: [.right(GlobNode(include: [.left(Set(["Source/**/*.m"]))]
                    ))])
        ))
    }

    func testWildCardSourceDependentSourceExclusionWithExistingExclusing() {
        let parentLib = ObjcLibrary(name: "Core", externalName: "Core",
            sourceFiles: AttrSet(basic: GlobNode(include:Set(["Source/*.m"]),
                                                 exclude:
                                                 Set(["Srce/SomeSource.m"]))))
        let childSourceFiles = basicGlob(include: Set(["Source/SomeSource.m"]))
        let depLib = ObjcLibrary(name: "ChildLib", externalName: "Core",
            sourceFiles: childSourceFiles,
            deps: AttrSet(basic: [":Core"]))
        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(
            libByName["ChildLib"]!.sourceFiles, 
            AttrSet(basic: GlobNode(
                include: [.left(Set(["Source/SomeSource.m"]))])
        ))

        XCTAssertEqual(
            libByName["Core"]!.sourceFiles,
            AttrSet(basic: GlobNode(
                include: [.left(Set(["Source/*.m"]))],
                exclude: [.left(Set(["Srce/SomeSource.m"])), .right(GlobNode(include: [.left(Set(["Source/SomeSource.m"]))]
                    ))])
            ))
    }

    func testNestedDependentExclusion() {
        let parentLib = ObjcLibrary(name: "Core", externalName: "Core",
            sourceFiles: basicGlob(include: Set(["Source/*.m"])))

        let depLib = ObjcLibrary(name: "ChildLib", externalName: "Core",
            sourceFiles: AttrSet(basic: GlobNode(include: Set(["Source/Foo/*.m"]))),
            deps: AttrSet(basic: [":Core"]))

        let depDepLib = ObjcLibrary(name: "GrandChildLib", externalName: "Core",
            sourceFiles: AttrSet(basic: GlobNode(include: Set(["Source/Foo/Bar/*.m"]))),
            deps: AttrSet(basic: [":ChildLib"]))

        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib, depDepLib])

        let transformed = libByName.values.map { $0.toSkylark() }
        print(SkylarkCompiler(.lines(transformed)).run())

        let childSources = libByName["ChildLib"]?.sourceFiles
        XCTAssertEqual(
            childSources, 
            AttrSet(basic: GlobNode(
                include: [.left(Set(["Source/Foo/*.m"]))],
                exclude: [.right(GlobNode(include: [.left(Set(["Source/Foo/Bar/*.m"]))]
                    ))]))

        )

        XCTAssertEqual(
            libByName["Core"]?.sourceFiles,
            AttrSet(basic: GlobNode(
                include: [.left(Set(["Source/*.m"]))],
                exclude: [
                .right(GlobNode(
                    include: [.left(Set(["Source/Foo/*.m"]))],
                    exclude: [])), .right(GlobNode(include: [.left(Set(["Source/Foo/Bar/*.m"]))], exclude: []))])
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

    // MARK: - Swift tests

    func testSwiftExtractionSubspec() {
        let podspec = examplePodSpecNamed(name: "ObjcParentWithSwiftSubspecs")
        let convs = PodBuildFile.makeConvertables(fromPodspec: podspec)
        XCTAssertEqual(convs.compactMap{ $0 as? ObjcLibrary }.count, 1)
        XCTAssertEqual(convs.compactMap{ $0 as? SwiftLibrary }.count, 1)
    }


    // MARK: - Source File Extraction Tests

    func testExtractionCurly() {
        let podPattern = "Source/Classes/**/*.{h,m}"
        let extractedHeaders = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: HeaderFileTypes).basic
        let extractedSources = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: ObjcLikeFileTypes).basic
        XCTAssertEqual(extractedHeaders, ["Source/Classes/**/*.h"])
        XCTAssertEqual(extractedSources, ["Source/Classes/**/*.m"])
    }

    func testExtractionWithBarPattern() {
        let podPattern = "Source/Classes/**/*.[h,m]"
        let extractedHeaders = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: HeaderFileTypes).basic
        let extractedSources = extractFiles(fromPattern: AttrSet(basic: [podPattern]),
                includingFileTypes: ObjcLikeFileTypes).basic

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

    func testHeaderIncAutoGlob() {
        let podSpec = examplePodSpecNamed(name: "UICollectionViewLeftAlignedLayout")
        let library = ObjcLibrary(parentSpecs: [], spec: podSpec)
        guard let ios = library.headers.multi.ios else {
            XCTFail("Missing iOS headers for lib \(library)")
            return
        }
        XCTAssertEqual(
            ios, GlobNode(include: Set([
                    "UICollectionViewLeftAlignedLayout/**/*.h",
                    "UICollectionViewLeftAlignedLayout/**/*.hpp",
                    "UICollectionViewLeftAlignedLayout/**/*.hxx"
                ]))
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
