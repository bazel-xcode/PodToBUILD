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

public struct PodRepositoryWorkspaceEntry: SkylarkConvertible {
    var name: String
    var url: String?
    var podspecURL: String?

    public func toSkylark() -> SkylarkNode {
        var args = [SkylarkFunctionArgument.named(name: "name", value: .string(name))]
        if let aUrl = url {
            args.append(.named(name: "url", value: .string(aUrl)))
        }
        if let aPodspecURL = podspecURL {
            args.append(.named(name: "podspec_url", value: .string(aPodspecURL)))
        }
        let repoSkylark = SkylarkNode.functionCall(name: "new_pod_repository",
                                                   arguments: args)
        return repoSkylark
    }
}

public struct PodsWorkspace: SkylarkConvertible {
    var pods: [PodRepositoryWorkspaceEntry] = []

    public init(lockfile: Lockfile, shell: ShellContext) throws {
        pods = try lockfile.dependencies.compactMap {
            depStr in
            let depName = String(depStr.split(separator: " ")[0])
            var sourceURL: String?
            var podspecURL: String?
            if let externalDepInfo = lockfile.externalSources[depName] {
                if let pathStr = externalDepInfo[":path"] {
                    sourceURL = pathStr
                }
                if let externalPodspecURL = externalDepInfo[":podspec"] {
                    podspecURL = externalPodspecURL
                }
            } else {
                let whichPod = shell.shellOut("which pod").standardOutputAsString
                if whichPod.isEmpty {
                    fatalError("RepoTools requires a cocoapod installation on host")
                }
                // This command loads a JSON podspec from the cocoapods
                // repository.
                // We only do this to get the source if it isn't provided, in
                // order to export a github URL
                let podBin = whichPod.components(separatedBy: "\n")[0]
                let localSpec = shell.command(podBin, arguments: ["spec", "which", depName])
                guard localSpec.terminationStatus == 0 else {
                    fatalError("""
                            PodSpec decoding failed \(localSpec.terminationStatus)
                            stdout: \(localSpec.standardOutputAsString)
                            stderr: \(localSpec.standardErrorAsString)
                    """)
                }
                let path = String(localSpec.standardOutputAsString.components(separatedBy:
                    "\n")[0])
                let podSpec = try PodsWorkspace.getPodspec(path: path)
                sourceURL = try? PodsWorkspace.getURL(podSpec: podSpec) ?? "unsupported"
            }

            return PodRepositoryWorkspaceEntry(
                name: depName,
                url: sourceURL,
                podspecURL: podspecURL
            )
        }
    }

    public func toSkylark() -> SkylarkNode {
        return .lines(pods.map { $0.toSkylark() })
    }

    static func getPodspec(path: String) throws -> PodSpec {
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path))
        guard let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
            JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
            let JSONPodspec = JSONFile as? JSONDict
        else {
            fatalError("Invalid JSON Podspec: (look inside \(path))")
        }
        return try PodSpec(JSONPodspec: JSONPodspec)
    }

    static func getURL(podSpec: PodSpec) throws -> String {
        guard let source = podSpec.source else {
            throw WorkspaceError.unsupportedSource
        }

        switch source {
        case let .git(url: gitURL, tag: .some(tag), commit: .none):
            guard gitURL.absoluteString.contains("github") else {
                throw WorkspaceError.unsupportedSource
            }
            return "\(gitURL.deletingPathExtension().absoluteString)/archive/\(tag ?? "").zip"
        case let .git(url: gitURL, tag: .none, commit: tag):
            return "\(gitURL.deletingPathExtension().absoluteString)/archive/\(tag ?? "").zip"
        case let .http(url: url):
            return url.absoluteString
        default:
            throw WorkspaceError.unsupportedSource
        }
    }
}
