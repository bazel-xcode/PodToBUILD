//
//  main.swift
//  RepoTools
//
//  Created by jerry on 4/17/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

setbuf(__stdoutp, nil)

// ShellContext is a wrapper around interactions with the shell
struct ShellContext {
    private let trace: Bool

    init(trace: Bool = false) {
        self.trace = trace
    }

    func command(_ launchPath: String, arguments: [String] = [String]()) -> Data {
        let data = startShellAndWait(launchPath, arguments: arguments)
        return data.0
    }

    func command(_ launchPath: String, arguments: [String] = [String]()) -> String {
        let data = startShellAndWait(launchPath, arguments: arguments)
        return String(data: data.0, encoding: String.Encoding.utf8) ?? ""
    }

    func command(_ launchPath: String, arguments: [String] = [String]()) {
        _ = startShellAndWait(launchPath, arguments: arguments)
    }

    func dir(_ path: String) {
        let dir = command("/bin/pwd").components(separatedBy: "\n")[0]
        let relativedir = escape("\(dir)/\(path)")
        log("DIR\(relativedir)")
        command("/bin/mkdir", arguments: ["-p", relativedir]) as Void
    }

    func symLink(from: String, to: String) {
        log("LINK FROM \(from) to \(to)")
        command("/bin/ln", arguments: ["-s", escape(from), escape(to)]) as Void
    }

    func write(value: String, toPath path: URL) {
        log("WRITE \(value) TO \(path)")
        try? value.write(to: path, atomically: false, encoding: String.Encoding.utf8)
    }

    // MARK: - Private

    private func escape(_ string: String) -> String {
        return string.replacingOccurrences(of: "\\", with: "\\\\", options: .literal, range: nil)
    }

    // Start a shell and wait for the result
    // @note we use UTF-8 here as the default language and the current env
    private func startShellAndWait(_ launchPath: String, arguments: [String] = [String]()) -> (Data, Data) {
        log("SHELL:\(launchPath) \(arguments)")
        let task = Process()
        task.launchPath = launchPath
        task.arguments = arguments
        var env = ProcessInfo.processInfo.environment
        env["LANG"] = "en_US.UTF-8"
        task.environment = env

        let stdout = Pipe()
        task.standardOutput = stdout

        let stderr = Pipe()
        task.standardError = stderr
        task.launch()
        task.waitUntilExit()

        let stderrData = stderr.fileHandleForReading.readDataToEndOfFile()
        let stdoutData = stdout.fileHandleForReading.readDataToEndOfFile()
        if trace {
            log("PIPE OUTPUT\(launchPath) \(arguments) stderr:\(readData(stderrData))  stdout:\(readData(stdoutData))")
        }

        return (stdoutData, stderrData)
    }

    private func readData(_ data: Data) -> String {
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }

    private func log(_ args: Any...) {
        if trace {
            print(args)
        }
    }
}

func main() {
    _ = CrashReporter()
    let buildOptions = BasicBuildOptions.parse(args: CommandLine.arguments)
    let shell = ShellContext(trace: buildOptions.trace)
    let whichPod = shell.command("/bin/bash", arguments: ["-l", "-c", "which pod"]) as String
    if whichPod.isEmpty {
        print("RepoTools requires a cocoapod installation on host")
        exit(1)
    }

    let podBin = whichPod.components(separatedBy: "\n")[0]

    let pwd = shell.command("/bin/pwd").components(separatedBy: "\n")[0]

    let podspecName = CommandLine.arguments[1]
    let jsonData = shell.command(podBin, arguments: ["ipc", "spec", podspecName + ".podspec"]) as Data

    guard let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
        JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
        let JSONPodspec = JSONFile as? JSONDict
    else {
        print("Invalid JSON Podspec")
        exit(1)
    }
    guard let podSpec = try? PodSpec(JSONPodspec: JSONPodspec) else {
        print("Cant read in podspec")
        exit(1)
    }

    shell.dir("bazel_support/Headers/Public")
    shell.dir("bazel_support/Headers/Private/")
    let publicHeaderdir = "bazel_support/Headers/Public/\(podspecName)"
    shell.dir(publicHeaderdir)

    // Create a directory structure condusive to <> imports
    // - Get all of the paths matching wild card imports
    // - Put them into the public header directory
    let buildFile = PodBuildFile.with(podSpec: podSpec, buildOptions: buildOptions)
    buildFile.skylarkConvertibles.flatMap { $0 as? RepoTools.ObjcLibrary }
        .flatMap { $0.headers }
        .flatMap { podGlob(pattern: $0) }
        .forEach { shell.symLink(from: "\(pwd)/\($0)", to: publicHeaderdir) }
    // Run the compiler
    let buildFileSkylarkCompiler = SkylarkCompiler(buildFile.skylarkConvertibles.flatMap { $0.toSkylark() })
    let buildFileOut = buildFileSkylarkCompiler.run()
    let buildFilePath = URL(fileURLWithPath: "BUILD", relativeTo: URL(fileURLWithPath: pwd))
    shell.write(value: buildFileOut, toPath: buildFilePath)
}

main()
