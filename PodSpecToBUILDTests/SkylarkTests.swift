//
//  PodSpecToBUILDTests.swift
//  PodSpecToBUILDTests
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import XCTest

class PodSpecToBUILDTests: XCTestCase {
    let nameArgument = SkylarkFunctionArgument.named(name: "name", value: .string(value: "test"))

    func testFunctionCall() {
        let call = SkylarkNode.functionCall(name: "objc_library", arguments: [nameArgument])
        let compiler = SkylarkCompiler([call])
        let expected = multilineString([
            "objc_library(",
            "  name = \"test\"",
            "  )\n",
        ])
        print(compiler.run())
        XCTAssertEqual(expected, compiler.run())
    }

    func testCallWithSkylark() {
        let sourceFiles = ["a.m", "b.m"]
        let globCall = SkylarkNode.functionCall(name: "glob", arguments: [.basic(value: .list(value: sourceFiles.map { .string(value: $0) }))])
        let srcsArg = SkylarkFunctionArgument.named(name: "srcs", value: globCall)
        let call = SkylarkNode.functionCall(name: "objc_library", arguments: [nameArgument, srcsArg])
        let compiler = SkylarkCompiler([call])
        let expected = multilineString([
            "objc_library(",
            "  name = \"test\",",
            "  srcs = glob(",
            "    [",
            "      \"a.m\",",
            "      \"b.m\"",
            "    ]",
            "    )",
            "  )\n",
        ])

        let expectedLines = expected.components(separatedBy: "\n")
        for (idx, line) in compiler.run().components(separatedBy: "\n").enumerated() {
            XCTAssertEqual(line, expectedLines[idx])
        }
    }

    func multilineString(_ values: [String]) -> String {
        return values.joined(separator: "\n")
    }
}
