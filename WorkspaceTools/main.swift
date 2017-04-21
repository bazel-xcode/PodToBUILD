//
//  main.swift
//  WorkspaceTools
//
//  Created by jerry on 4/21/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

func main() {
    if CommandLine.arguments.count < 2 {
        // First, print a JSON rep of a Pod spec
        // pod spec cat PINCache
        print("Usage: somePodspec.json")
        exit(0)
    }

    let JSONPodspecFile = CommandLine.arguments[1]
    guard let jsonData = NSData(contentsOfFile: JSONPodspecFile) as? Data,
        let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
            JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
        let JSONPodspec = JSONFile as? JSONDict,
        let podSpec = try? PodSpec(JSONPodspec: JSONPodspec)
    else {
        print("Invalid JSON Podspec")
        exit(1)
    }

    guard let workspaceEntry = try? PodRepositoryWorkspaceEntry.with(podSpec: podSpec) else {
        print("Unsupported source type")
        exit(1)
    }

    let buildFileSkylarkCompiler = SkylarkCompiler(workspaceEntry.toSkylark())
    print(buildFileSkylarkCompiler.run())
}

main()
