//
//  TestUtils.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/21/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

// Get a JSON Podspec from a file
func podSpecWithFixture(JSONPodspecFilePath: String) -> PodSpec {
    guard let jsonData = NSData(contentsOfFile: JSONPodspecFilePath) as? Data,
        let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
            JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
        let JSONPodspec = JSONFile as? JSONDict,
        let podSpec = try? PodSpec(JSONPodspec: JSONPodspec) else {
        fatalError()
    }
    return podSpec
}

// Assume the directory structure relative to this file
private func srcRoot() -> String {
    let componets = #file .components(separatedBy: "/")
    return componets[0 ... componets.count - 3].joined(separator: "/")
}

func examplePodSpecNamed(name: String) -> PodSpec {
    let dir = "\(srcRoot())/Examples/"
    let path = Bundle.path(forResource: "\(name).podspec", ofType: "json", inDirectory: dir)
    let podSpec = podSpecWithFixture(JSONPodspecFilePath: path!)
    return podSpec
}
