//
//  BasicBuildOptionsTest.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 5/2/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import XCTest
@testable import PodToBUILD
@testable import RepoToolsCore

class BasicBuildOptionsTest: XCTestCase {
    func testUserOptions() {
        let CLIArgs = ["./path/to/Pod",
                       "Pod",
                       "init",
                       "--user_option",
                       "Foo.bar = -bang"
        ]
        let action = SerializedRepoToolsAction.parse(args: CLIArgs)
        guard case let .initialize(options) = action else {
           XCTFail()
           return
        }
        XCTAssertEqual(options.podName, "Pod")
        XCTAssertEqual(options.userOptions[0], "Foo.bar = -bang")
    }

    func testMultipleUserOptions() {
        let CLIArgs = ["./path/to/Pod",
                       "Pod",
                       "init",
                       "--user_option",
                       "Foo.bar = -bang",
                       "--user_option",
                       "Foo.bash = -crash"
        ]
        let action = SerializedRepoToolsAction.parse(args: CLIArgs)
        guard case let .initialize(options) = action else {
           XCTFail() 
           return
        }
        XCTAssertEqual(options.podName, "Pod")
        XCTAssertEqual(options.userOptions[0], "Foo.bar = -bang")
        XCTAssertEqual(options.userOptions[1], "Foo.bash = -crash")
    }

    func testFrontendOptions() {
        let CLIArgs = ["./path/to/Pod",
                       "Pod",
                       "init",
                       "--generate_module_map",
                       "true",
                       "--enable_modules",
                       "true",
                       "--header_visibility",
                       "pod_support",
        ]
        let action = SerializedRepoToolsAction.parse(args: CLIArgs)
        guard case let .initialize(options) = action else {
           XCTFail()
           return
        }
        XCTAssertEqual(options.podName, "Pod")
        XCTAssertEqual(options.enableModules, true)
        XCTAssertEqual(options.generateModuleMap, true)
        XCTAssertEqual(options.headerVisibility, "pod_support")
    }
}
