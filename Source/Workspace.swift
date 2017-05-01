//
//  Workspace.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/14/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

// __Podspec__
// "source": {
//  "git": "https://github.com/Flipboard/FLAnimatedImage.git",
//  "tag": "1.0.12"
// },
// ___
//
// Example:
// new_pod_repository(
//   name = "FLAnimatedImage",
//   url = "https://github.com/Flipboard/FLAnimatedImage/archive/1.0.12.zip",
//   strip_prefix = "FLAnimatedImage-1.0.12"
// )

enum WorkspaceError: Error {
    case unsupportedSource
}

struct PodRepositoryWorkspaceEntry: SkylarkConvertible {
    var name: String
    var url: String
    var stripPrefix: String

    func toSkylark() -> SkylarkNode {
        let repoSkylark = SkylarkNode.functionCall(name: "new_pod_repository", arguments: [
            .named(name: "name", value: .string(name)),
            .named(name: "url", value: .string(url)),
            .named(name: "strip_prefix", value: .string(stripPrefix)),
        ])
        return repoSkylark
    }

    static func with(podSpec: PodSpec) throws -> PodRepositoryWorkspaceEntry {
        guard let source = podSpec.source,
            let git = source.git,
            let tag = source.tag
        else {
            throw WorkspaceError.unsupportedSource
        }
        if git.contains("github") == false {
            throw WorkspaceError.unsupportedSource
        }
        let repoBaseURL = git.replacingOccurrences(of: ".git", with: "")
        let url = "\(repoBaseURL)/archive/\(tag).zip"
        let guessedStripPrefix = "\(podSpec.name)-\(tag)"
        return PodRepositoryWorkspaceEntry(name: podSpec.name, url: url, stripPrefix: guessedStripPrefix)
    }
}
