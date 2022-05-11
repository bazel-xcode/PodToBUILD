//
//  Git.swift
//  
//
//  Created by Crazy凡 on 2022/5/10.
//

import Foundation
import PodToBUILD

private struct GitOptions {
    enum Options: String {
        case commit, tag, branch, submodules
    }

    let podName: String
    let url: String
    var options: [Options: String]
    var submodules: Bool {
        return options[.submodules] == "true"
    }

    init?(_ options: FetchOptions) {
        guard GitOptions.isGitURL(options.url) else {
            return nil
        }

        self.podName = options.podName
        self.url = options.url

        if let revision = options.revision, !revision.isEmpty {
            let options: [Options: String] = revision.split(separator: ";")
                .reduce(into: [:]) { (result, item) in
                    let items = item.split(separator: ":")
                    if items.count == 2, let key = Options(rawValue: String(items[0])) {
                        result[key] = String(items[1])
                    } else {
                        fatalError("Invalid revision: \(revision)")
                    }
                }
            if options.keys.contains(.branch), options.keys.contains(.tag) {
                fatalError("Invalid revision: \(revision), can't have both branch and tag")
            }

            self.options = options
        } else {
            self.options = [.branch: "master"]
        }
    }

    private static func isGitURL(_ url: String) -> Bool {
        return url.hasPrefix("git@")
    }
}

struct GitDownloader: Downloader {
    private var options: GitOptions

    init?(options: FetchOptions, shell: ShellContext) {
        guard let _options = GitOptions(options) else {
            return nil
        }

        self.options = _options
        preprocess(shell: shell, options: &self.options.options)
    }

    func cacheRoot() -> String {
        PodStoreCacheDir + options.podName + "-" + options.url.sha256() + "/" + options.options[.commit]! + (options.submodules ? "-submodules" : "")
    }

    func download(shell: ShellContext) -> String {
        clone(shell: shell)
    }
}

private extension GitDownloader {
    // preprocess git options
    func preprocess(shell: ShellContext, options: inout [GitOptions.Options: String]) {
        guard let branch = options[.branch] ?? options[.tag] else {
            return
        }

        let command = [
            "git",
            "ls-remote",
            "--",
            self.options.url,
            branch
        ].joined(separator: " ")

        let result = shell.command(CommandBinary.sh, arguments: ["-c", command])
        if result.terminationStatus != 0 {
            fatalError("Can not get remote branch: \(branch)")
        }

        guard let match = commitFromLsRemote(output: result.standardOutputAsString, name: branch) else { return }

        options[.commit] = match

        options.removeValue(forKey: .branch)
        options.removeValue(forKey: .tag)
    }

    func commitFromLsRemote(output: String, name: String) -> String? {
        for line in output.split(separator: "\n") {
            let items = line.split(separator: "\t")
            guard items.count == 2 else {
                continue
            }

            let commit = items[0]
            let ref = String(items[1]).trimmingCharacters(in: .whitespaces)
            if ref == "refs/heads/\(name)" || ref == "refs/tags/\(name)" {
                return String(commit).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    func cloneArguments(
        shell: ShellContext,
        forceHead: Bool = false, // keep
        shallowClone: Bool = true,
        targetPath: String
    ) -> [String] {
        var command = ["git", "clone", options.url, targetPath, "--template="]

        if shallowClone, !options.options.keys.contains(.commit) {
            command += ["--single-branch", "--depth=1"]
        }

        if !forceHead, let tag_or_branch = options.options[.tag] ?? options.options[.branch] {
            command += ["--branch", tag_or_branch]
        }

        return command
    }

    func clone(
        shell: ShellContext,
        forceHead: Bool = false,
        shallowClone: Bool = true
    ) -> String {
        let targetPath = shell.tmpdir() + "/\(options.podName)/git/cache"

        func clone(_ shallowClone: Bool) -> CommandOutput {
            let gitCommand = cloneArguments(
                shell: shell,
                forceHead: forceHead,
                shallowClone: shallowClone,
                targetPath: targetPath
            ).joined(separator: " ")
                            
            return shell.command(CommandBinary.sh, arguments: ["-c", gitCommand])
        }

        let result = clone(shallowClone)

        if result.terminationStatus != 0 {
            if shallowClone, result.standardOutputAsString.contains("does not support") {
                let retryResult = clone(false)
                if retryResult.terminationStatus != 0 {
                    fatalError("Can not clone git repository: \(options.url)\nError: \(result.standardErrorAsString)")
                }
            } else {
                fatalError("Can not clone git repository: \(options.url)\nError: \(result.standardErrorAsString)")
            }
        }

        if let commit = options.options[.commit] {
            shell.command(CommandBinary.sh, arguments: ["-c", "git -C \(targetPath) checkout \(commit)"])
        }

        if options.submodules {
            shell.command(CommandBinary.sh, arguments: ["-c", "git -C \(targetPath) submodule update --init --recursive"])
        }

        return targetPath
    }
}
