//
//  BasicBuildOptionsTest.swift
//  PodSpecToBUILD
//
//  Created by jerry on 5/2/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import XCTest

class BasicBuildOptionsTest: XCTestCase {
    func testUserOptions() {
        let CLIArgs = ["./path/to/Pod",
                       "Pod",
                       "--user_option",
                       "Foo.bar = -bang"
        ]
        let options = BasicBuildOptions.parse(args: CLIArgs)
        XCTAssertEqual(options.podName, "Pod")
        XCTAssertEqual(options.userOptions[0], "Foo.bar = -bang")
    }

    func testMultipleUserOptions() {
        let CLIArgs = ["./path/to/Pod",
                       "Pod",
                       "--user_option",
                       "Foo.bar = -bang",
                       "--user_option",
                       "Foo.bash = -crash"
        ]
        let options = BasicBuildOptions.parse(args: CLIArgs)
        XCTAssertEqual(options.podName, "Pod")
        XCTAssertEqual(options.userOptions[0], "Foo.bar = -bang")
        XCTAssertEqual(options.userOptions[1], "Foo.bash = -crash")
    }
}
