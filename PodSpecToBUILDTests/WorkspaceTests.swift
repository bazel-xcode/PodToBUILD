//
//  WorkspaceTests.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/21/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import XCTest

class WorkspaceTests: XCTestCase {
    func testWorkspaceEndToEndJSONParsing() {
        let podSpec = examplePodSpecNamed(name: "FLAnimatedImage")
        let workspaceEntry = try! PodRepositoryWorkspaceEntry.with(podSpec: podSpec)
        XCTAssertEqual(workspaceEntry.name, "FLAnimatedImage")
        XCTAssertEqual(workspaceEntry.url.absoluteString, "https://github.com/Flipboard/FLAnimatedImage/archive/1.0.12.zip")
        XCTAssertEqual(workspaceEntry.stripPrefix, "FLAnimatedImage-1.0.12")
    }
}
