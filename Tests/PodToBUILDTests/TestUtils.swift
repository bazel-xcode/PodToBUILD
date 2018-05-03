//
//  TestUtils.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/21/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation
@testable import PodToBUILD

// Get a JSON Podspec from a file
func podSpecWithFixture(JSONPodspecFilePath: String) -> PodSpec {
    guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: JSONPodspecFilePath)) else {
        fatalError("Error: Unable to load podspec at \(JSONPodspecFilePath)")
    }

    guard let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
        JSONSerialization.ReadingOptions.allowFragments) else {
        fatalError("Error: Unable to parse JSON podspec at \(JSONPodspecFilePath)")
    }


    guard let JSONPodspec = JSONFile as? JSONDict  else {
        fatalError("Error: JSON for podspec is malformed. Expected [String:Any] for podspec at: \(JSONPodspecFilePath)")
    }


    guard let podSpec = try? PodSpec(JSONPodspec: JSONPodspec) else {
        fatalError("Error: JSON podspec is invalid. Look for missing fields or incorrect data types: \(JSONPodspecFilePath)")
    }

    return podSpec
}

// Assume the directory structure relative to this file
// ( PodToBUILD/Tests/PodToBUILDTests/#file )
private func srcRoot() -> String {
    let componets = #file .components(separatedBy: "/")
    return componets[0 ... componets.count - 4].joined(separator: "/")
}

public func examplePodSpecFilePath(name: String) -> String {
    let dir = "\(srcRoot())/Examples/"
    let path = Bundle.path(forResource: "\(name).podspec", ofType: "json", inDirectory: dir)
    return path!
}

public func examplePodSpecNamed(name: String) -> PodSpec {
    let podSpec = podSpecWithFixture(JSONPodspecFilePath: examplePodSpecFilePath(name: name))
    return podSpec
}
