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

class BuildTests: XCTestCase {
    let shell = SystemShellContext(trace: true)
    // Build tests are a lightweight hook into examples
    func testEverything() {
        // Travis will throw errors if the process doesn't output after 10 mins.
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { timer in
            print("[INFO] Build tests still running...")
        }

        let components = #file .split(separator: "/")
        let rootDir = "/" + components [0 ... components.count - 4].joined(separator: "/")

        let examples = ["React", "PINRemoteImage", "Texture", "BasiciOS"]
        examples.forEach {
            example in
            let fetchTask = ShellTask(command: "/bin/bash", arguments: [
                    "-c",
                    "make -C \(rootDir)/Examples/\(example) fetch"
                    ], timeout: 1200.0)
            let fetchResult = fetchTask.launch()
            XCTAssertEqual(fetchResult.terminationStatus, 0)
            guard fetchResult.terminationStatus == 0 else {
                fatalError(
                        "Can't setup test root."
                                + "\nCMD:\n\(fetchTask.debugDescription)"
                                + "\nSTDOUT:\n\(fetchResult.standardOutputAsString)"
                                + "\nSTDERR:\n\(fetchResult.standardErrorAsString)"
                )
            }
            let bazelScript = "make -C \(rootDir)/Examples/\(example)"
            print("running bazel:", bazelScript)
            let buildResult = ShellTask(command: "/bin/bash", arguments: [
                    "-c", bazelScript ], timeout: 1200.0).launch()
            XCTAssertEqual(buildResult.terminationStatus, 0, "building \(example)")
            print("Bazel completed with stderror:", buildResult.standardErrorAsString)
            print("Bazel completed with stdout:", buildResult.standardOutputAsString)

            // For now, we assume that the if bazel exits with 0 it passed.
            if buildResult.terminationStatus != 0 {
                print("Bazel failed with stderror:", buildResult.standardErrorAsString)
                print("Bazel failed with stdout:", buildResult.standardOutputAsString)
            }
        }
    }
}

