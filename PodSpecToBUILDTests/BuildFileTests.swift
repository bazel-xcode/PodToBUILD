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
                                    sourceFiles: ["Source/*.m"],
                                    headers: [String](),
                                    sdkFrameworks: [String](),
                                    deps: [String](),
                                    copts: [String](),
                                    excludedSource: [String]())

        let depLib = ObjcLibrary(name: "ChildLib",
                                 sourceFiles: ["Source/SomeSource.m"],
                                 headers: [String](),
                                 sdkFrameworks: [String](),
                                 deps: [":Core"],
                                 copts: [String](),
                                 excludedSource: [String]())
        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(libByName["Core"]!.excludedSource, ["Source/SomeSource.m"])
    }

    func testWildCardDirectoryDependentSourceExclusion() {
        let parentLib = ObjcLibrary(name: "Core",
                                    sourceFiles: ["Source/**/*.m"],
                                    headers: [String](),
                                    sdkFrameworks: [String](),
                                    deps: [String](),
                                    copts: [String](),
                                    excludedSource: [String]())

        let depLib = ObjcLibrary(name: "ChildLib",
                                 sourceFiles: ["Source/Some/Source.m"],
                                 headers: [String](),
                                 sdkFrameworks: [String](),
                                 deps: [":Core"],
                                 copts: [String](),
                                 excludedSource: [String]())
        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(libByName["Core"]!.excludedSource, ["Source/Some/Source.m"])
    }

    func testWildCardSourceDependentSourceExclusionWithExistingExclusing() {
        let parentLib = ObjcLibrary(name: "Core",
                                    sourceFiles: ["Source/*.m"],
                                    headers: [String](),
                                    sdkFrameworks: [String](),
                                    deps: [String](),
                                    copts: [String](),
                                    excludedSource: ["Srce/SomeSource.m"])

        let depLib = ObjcLibrary(name: "ChildLib",
                                 sourceFiles: ["Source/SomeSource.m"],
                                 headers: [String](),
                                 sdkFrameworks: [String](),
                                 deps: [":Core"],
                                 copts: [String](),
                                 excludedSource: [String]())
        let libByName = executePruneRedundantCompilationTransform(libs: [parentLib, depLib])
        XCTAssertEqual(libByName["ChildLib"]!.excludedSource, [String]())
        XCTAssertEqual(libByName["Core"]!.excludedSource, ["Srce/SomeSource.m", "Source/SomeSource.m"])
    }

    private func executePruneRedundantCompilationTransform(libs: [ObjcLibrary]) -> [String: ObjcLibrary] {
        let transformed = PodBuildFile.executePruneRedundantCompilationTransform(libs: libs)
        var libByName = [String: ObjcLibrary]()
        for lib in transformed {
            libByName[lib.name] = lib
        }
        return libByName
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
}
