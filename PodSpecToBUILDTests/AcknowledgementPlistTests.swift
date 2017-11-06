//
//  AcknowledgementPlistTests.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 6/19/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import XCTest

class AcknowledgementPlistTests: XCTestCase {
    func testTextLicense() {
        let podspec = examplePodSpecNamed(name: "Calabash")
        XCTAssertEqual(podspec.license.type, "Eclipse Public License 1.0")
        XCTAssertNotNil(podspec.license.text)
    }

    func testTypeString() {
        let podspec = examplePodSpecNamed(name: "Braintree")
        XCTAssertEqual(podspec.license.type, "MIT")
    }

    func testEntry() {
        let podspec = examplePodSpecNamed(name: "Calabash")
        let entry = AcknowledgmentEntry(forPodspec: podspec)
        XCTAssertEqual(entry["Title"], "Calabash")
        XCTAssertEqual(entry["Type"], "PSGroupSpecifier")
        XCTAssertEqual(entry["License"], "Eclipse Public License 1.0")
        XCTAssertNotNil(entry["FooterText"])
    }
}
