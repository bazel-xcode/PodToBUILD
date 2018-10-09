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
    let bazelVersion = "0.12.0rc1"

    /// Build Tests: Test that a given Pod can build end to end.
    /// 1) Setup a test workspace.
    /// 2) Copy over the Pods.WORKSPACE for the given example case.
    /// 3) Run bazel and check output.
    /// Ideally: we can build all of the specs:
    /// `bazel build //Vendor/Pod:*`
    func build(pod: String, specs: [String] = ["*"]) {
        let components = #file .split(separator: "/")
        let rootDir = "/" + components [0 ... components.count - 4].joined(separator: "/")

        // Warning: we don't totally tear down the sandbox after every
        // test method invocation.
        // This is an implementation detail and in a way, is ideal for an
        // integration test due to the nature of how the user is constantly
        // changing and updating cocoapods.
        let sandbox = "/var/tmp/PodTestSandbox"
        let podSandbox = sandbox + "/Vendor/\(pod)"
        shell.dir(podSandbox)
        shell.shellOut("ditto $PWD \(sandbox)/Vendor/rules_pods")
        shell.shellOut("ditto \(rootDir)/Tests/BuildTests/Examples/\(pod)/* \(sandbox)/")
        shell.shellOut("ditto \(rootDir)/Tests/BuildTests/Examples/PodSpecs \(sandbox)/Vendor/PodSpecs")
        let task = ShellTask(command: "/bin/bash", arguments: [
                "-c",
                "Vendor/rules_pods/bin/update_pods.py"
                ], timeout: 1200.0, cwd: sandbox)
        let result = task.launch()
        XCTAssertEqual(result.terminationStatus, 0)
        print("PodUpdate Result:", result.standardOutputAsString)
        print("PodUpdate Result:", result.standardErrorAsString)
        guard result.terminationStatus == 0 else {
            fatalError("Can't setup test root")
        }

        // Setup the bazel directory
        shell.shellOut("touch \(sandbox)/WORKSPACE")
        shell.shellOut("touch \(sandbox)/BUILD")
        shell.shellOut("touch \(sandbox)/Vendor/BUILD")
        specs.forEach {
            spec in
            let label = "//Vendor/\(pod):\(spec)"
            let bazelScript = "~/.bazelenv/versions/\(bazelVersion)/bin/bazel build \(label)"
            print("running bazel:", bazelScript)
            let buildResult = ShellTask(command: "/bin/bash", arguments: [
                    "-c", bazelScript ], timeout: 1200.0, cwd: sandbox).launch()
            XCTAssertEqual(buildResult.terminationStatus, 0, "building \(label)")
            print("Bazel completed with stderror:", buildResult.standardErrorAsString)
            print("Bazel completed with stdout:", buildResult.standardOutputAsString)

            // For now, we assume that the if bazel exits with 0 it passed.
            if buildResult.terminationStatus != 0 {
                print("Bazel failed with stderror:", buildResult.standardErrorAsString)
                print("Bazel failed with stdout:", buildResult.standardOutputAsString)
            }
        }
    }

    func testPINRemoteImage() {
        build(pod: "PINRemoteImage", specs: ["Core"])
    }

    func testRN() {
        build(pod: "React", specs: [
             "Core",
             "RCTAnimation",
             "CxxBridge",
             "DevSupport",
             "RCTImage",
             "RCTNetwork",
             "RCTText",
             "RCTWebSocket",
             ])
    }

    func testTexture() {
        build(pod: "Texture", specs: ["AsyncDisplayKit"])
    }
}

