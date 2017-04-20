//
//  Workspace.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

struct NewGitRepository {
    var name: String
    var remote: String
    var tag: String

    init(JSONPodspec: JSONDict) throws {
        name = try ExtractValue(fromJSON: JSONPodspec["name"])
        let sourceJSON = try ExtractValue(fromJSON: JSONPodspec["source"]) as JSONDict
        remote = try ExtractValue(fromJSON: sourceJSON["git"])
        tag = try ExtractValue(fromJSON: sourceJSON["tag"])
    }
}
