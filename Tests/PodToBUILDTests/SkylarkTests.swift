//
//  PodSpecToBUILDTests.swift
//  PodSpecToBUILDTests
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import XCTest
@testable import PodToBUILD

class PodSpecToBUILDTests: XCTestCase {
    let nameArgument = SkylarkFunctionArgument.named(name: "name", value: "test")

    func testFunctionCall() {
        let call = SkylarkNode.functionCall(name: "objc_library", arguments: [nameArgument])
        let compiler = SkylarkCompiler([call])
        let expected = compilerOutput([
            "objc_library(",
            "  name = \"test\"",
            "  )",
        ])
        print(compiler.run())
        XCTAssertEqual(expected, compiler.run())
    }

    func testCallWithSkylark() {
        let sourceFiles = ["a.m", "b.m"]
        let globCall = SkylarkNode.functionCall(name: "glob", arguments: [.basic(sourceFiles.toSkylark())])
        let srcsArg = SkylarkFunctionArgument.named(name: "srcs", value: globCall)
        let call = SkylarkNode.functionCall(name: "objc_library", arguments: [nameArgument, srcsArg])
        let compiler = SkylarkCompiler([call])
        let expected = compilerOutput([
            "objc_library(",
            "  name = \"test\",",
            "  srcs = glob(",
            "    [",
            "      \"a.m\",",
            "      \"b.m\"",
            "    ]",
            "    )",
            "  )",
        ])

        let expectedLines = expected.components(separatedBy: "\n")
        for (idx, line) in compiler.run().components(separatedBy: "\n").enumerated() {
            XCTAssertEqual(line, expectedLines[idx])
        }
    }

    func compilerOutput(_ values: [String]) -> String {
        return values.joined(separator: "\n")
    }
}
