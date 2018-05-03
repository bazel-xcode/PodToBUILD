//
//  ShellTaskTest.swift
//  PodSpecToBUILDTests
//
//  Created by Jerry Marino on 9/27/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import XCTest
@testable import PodToBUILD

class ShellTaskTest: XCTestCase {
    
    func testCanExecute() {
        let task = ShellTask(command: "/usr/bin/whoami", arguments: [], timeout: 1.0)
        let resultStr = task.launch().standardOutputAsString
        XCTAssertTrue(resultStr.count > 0)
    }
    
    func testBashScript() {
        let task = ShellTask.with(script: "echo \"hi\"", timeout: 0.5)
        let resultStr = task.launch().standardOutputAsString
        // For now, this is required. There is a new line in this output
        XCTAssertEqual(resultStr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines), "hi")
    }

    /// For now, timeouts just fail silently. It's up to the caller to
    /// check if they have the correct output.
    func testTimeout() {
        let task = ShellTask.with(script: "sleep 10", timeout: 1.0)
        let status = task.launch().terminationStatus
        XCTAssertNotEqual(status, 0)
    }
}
