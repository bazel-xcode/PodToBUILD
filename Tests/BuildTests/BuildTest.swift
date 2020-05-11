//
//  BuildTest.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 6/18/18.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import XCTest
@testable import PodToBUILD
import Foundation

class BuildTest: XCTestCase {
    let shell = SystemShellContext(trace: true)

    func srcRoot() -> String {
        // This path is set by Bazel
        guard let testSrcDir = ProcessInfo.processInfo.environment["TEST_SRCDIR"] else{
            fatalError("Missing bazel test base")
        }
        let componets = testSrcDir.components(separatedBy: "/")
        return componets[0 ... componets.count - 5].joined(separator: "/")
    }

    func run(_ example: String) {
        // Travis will throw errors if the process doesn't output after 10 mins.
        let timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { timer in
            print("[INFO] Build tests still running...")
        }

        let rootDir = srcRoot()
        // Give 3 attempts to do the fetch. This is a workaround for flaky
        // networking
        let firstFetchResult = (0...3).lazy.compactMap {
        i -> CommandOutput? in
            sleep(UInt32(i * 3))
            print("Starting fetch task", i, example)
            let fetchTask = ShellTask(command: "/bin/bash", arguments: [
                    "-c",
                    "make -C \(rootDir)/Examples/\(example) fetch"
                    ], timeout: 1200.0, printOutput: true)
            let fetchResult = fetchTask.launch()
            if fetchResult.terminationStatus == 0 {
                return fetchResult
            }
            return nil
        }.first

        guard let fetchResult = firstFetchResult else {
            fatalError("Can't setup test root.")
        }
        XCTAssertEqual(fetchResult.terminationStatus, 0)
        let bazelScript = "make -C \(rootDir)/Examples/\(example)"
        print("running bazel:", bazelScript)
        let buildResult = ShellTask(command: "/bin/bash", arguments: [
                "-c", bazelScript ], timeout: 1200.0, printOutput: true).launch()
        timer.invalidate()
        XCTAssertEqual(buildResult.terminationStatus, 0, "building \(example)")
    }

    func testReact() {
        // This test is flaky
        // run("React")
    }

    func testPINRemoteImage() {
        run("PINRemoteImage")
    }

    func testTexture() {
        run("Texture")
    }

    func testBasiciOS() {
        run("BasiciOS")
    }
}

