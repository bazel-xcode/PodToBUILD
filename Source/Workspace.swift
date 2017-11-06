//
//  Workspace.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/14/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
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
    var url: URL
    var stripPrefix: String

    func toSkylark() -> SkylarkNode {
        let repoSkylark = SkylarkNode.functionCall(name: "new_pod_repository", arguments: [
            .named(name: "name", value: .string(name)),
            .named(name: "url", value: .string(url.absoluteString)),
            .named(name: "strip_prefix", value: .string(stripPrefix)),
        ])
        return repoSkylark
    }

    static func with(podSpec: PodSpec) throws -> PodRepositoryWorkspaceEntry {
        guard let source = podSpec.source else {
            throw WorkspaceError.unsupportedSource
        }

        switch source {
        case let .git(url: gitURL, tag: .some(tag), commit: .none):
            guard gitURL.absoluteString.contains("github") else {
                throw WorkspaceError.unsupportedSource
            }
            guard let url = URL(string: "\(gitURL.deletingPathExtension().absoluteString)/archive/\(tag).zip") else {
                throw WorkspaceError.unsupportedSource
            }
            
            let guessedStripPrefix = "\(podSpec.name)-\(tag)"
            return PodRepositoryWorkspaceEntry(name: podSpec.name, url: url, stripPrefix: guessedStripPrefix)
        case .git(url: _, tag: .none, commit: .some(_)):
            // TODO: Support commit hashes
            throw WorkspaceError.unsupportedSource
        case let .http(url: url):
            let guessedStripPrefix = url.deletingPathExtension().lastPathComponent
            return PodRepositoryWorkspaceEntry(name: podSpec.name, url: url, stripPrefix: guessedStripPrefix)
        default:
            throw WorkspaceError.unsupportedSource
        }
    }
}
