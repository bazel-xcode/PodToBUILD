//
//  GlobTests.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/18/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import XCTest
import Foundation

class GlobTests: XCTestCase {
    func testGarbageGlob() {
        let path = "Garbage/Source/*.{h,m}"
        XCTAssertFalse(glob(pattern: path, contains: ""))
    }
    
    func testIteration() {
        XCTAssertTrue(glob(pattern: "A", contains: "A"))
        XCTAssertTrue(glob(pattern: "A/Some", contains: "A/Some"))
        XCTAssertFalse(glob(pattern: "A/Some/Source", contains: "A/Some/**"))
        XCTAssertTrue(glob(pattern: "A/Some/**", contains: "A/Some/Source"))
    }

    func testGlobMatchingNoMatch() {
        let testPattern = "^*.[h]"
        XCTAssertFalse(glob(pattern: testPattern, contains: "/Some/Path/*.m"))
    }

    func testGlobMatching() {
        let testPattern = "^*.[h]"
        XCTAssertFalse(glob(pattern: testPattern, contains: "/Some/Path/*.h"))
    }

    func testPodRegexConversion() {
        let testPattern = NSRegularExpression.pattern(withGlobPattern: "Source/Classes/**/*.{h,m}")
        XCTAssertEqual(testPattern, "Source/Classes/.*.*/.*.[h,m]")
    }
    
    func testNaievePatternBuilding() {
        let testPattern = pattern(fromPattern: "Source/Classes/**/*.{h,m}", includingFileType: "h")
        XCTAssertEqual(testPattern, "Source/Classes/**/*.h")
    }

    func testFalsePositiveBasic() {
        let testPattern = pattern(fromPattern: "Source/Classes/**/*.py", includingFileType: "m")
        XCTAssertNil(testPattern)
    }

    func testNaievePatternBuildingSecondPart() {
        let testPattern = pattern(fromPattern: "Source/Classes/**/*.{h,m}", includingFileType: "m")
        XCTAssertEqual(testPattern, "Source/Classes/**/*.m")
    }

    func testNaievePatternBuildingBar() {
        let testPattern = pattern(fromPattern: "Source/Classes/**/*.{h|m}", includingFileType: "m")
        XCTAssertEqual(testPattern, "Source/Classes/**/*.m")
    }

    func testNaievePatternBuildingMismatch() {
        let testPattern = pattern(fromPattern: "Source/Classes/**/*.{h}", includingFileType: "m")
        XCTAssertNil(testPattern)
    }
    
    func testBoltsStylePattern() {
        let sources = pattern(fromPattern: "Source/Classes/**/*.[hm]", includingFileType: "m")
        XCTAssertEqual(sources, "Source/Classes/**/*.m")
        
        let headers = pattern(fromPattern: "Source/Classes/**/*.[hm]", includingFileType: "h")
        XCTAssertEqual(headers, "Source/Classes/**/*.h")
    }

    func testPatternsEndingInAlphanumericCharactersYieldGlob() {
        let testPattern = pattern(fromPattern: "Source/Classes", includingFileType: "m")
        XCTAssertEqual(testPattern, "Source/Classes/**/*.m")
    }
}
