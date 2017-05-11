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
    
    func command(forErrorCode launchPath: String, arguments: [String] = [String]()) -> Int {
        let (_, _, code) = startShellAndWait(launchPath, arguments: arguments)
        return code
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
    private func startShellAndWait(_ launchPath: String, arguments: [String] = [String]()) -> (Data, Data, Int) {
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
        let statusCode = task.terminationStatus
        if trace {
            log("PIPE OUTPUT\(launchPath) \(arguments) stderr:\(readData(stderrData))  stdout:\(readData(stdoutData)) code:\(statusCode)")
        }

        return (stdoutData, stderrData, Int(statusCode))
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
        fatalError("RepoTools requires a cocoapod installation on host")
    }
    let podspecName = CommandLine.arguments[1]
    let pwd = shell.command("/bin/pwd").components(separatedBy: "\n")[0]
    
    // make json data
    let jsonData: Data;
    let hasFile: (String) -> Bool = { file in
        // did you know that [ is the name of the binary that tests stuff!
        shell.command(forErrorCode: "/bin/[",
                      arguments: ["-e", file, "]"]) == 0
    }
    let hasPodspec: () -> Bool = { hasFile(podspecName + ".podspec") }
    let hasPodspecJson: () -> Bool = { hasFile(podspecName + ".podspec.json") }
    
    if hasPodspec() {
        let podBin = whichPod.components(separatedBy: "\n")[0]
        jsonData = shell.command(podBin, arguments: ["ipc", "spec", podspecName + ".podspec"]) as Data
    } else if hasPodspecJson() {
        jsonData = shell.command("/bin/cat", arguments: [podspecName + ".podspec.json"]) as Data
    } else {
        fatalError("Missing podspec!")
    }

    guard let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
        JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
        let JSONPodspec = JSONFile as? JSONDict
    else {
        fatalError("Invalid JSON Podspec")
    }

    guard let podSpec = try? PodSpec(JSONPodspec: JSONPodspec) else {
        fatalError("Cant read in podspec")
    }


    shell.dir("bazel_support/Headers/Public")
    shell.dir("bazel_support/Headers/Private/")


    let searchPaths = { (spec: ComposedSpec) -> Set<String> in
        let fallbackSpec = spec
        let moduleName = AttrSet<String>(
            value: fallbackSpec ^* ComposedSpec.lens.fallback(PodSpec.lens.liftOntoPodSpec(PodSpec.lens.moduleName))
        )
        let headerDirectoryName: AttrSet<String?> = fallbackSpec ^* ComposedSpec.lens.fallback(liftToAttr(PodSpec.lens.headerDirectory))
        guard let externalName = (moduleName.isEmpty ? nil : moduleName) ??
            (headerDirectoryName.isEmpty ? nil : headerDirectoryName.denormalize()) else {
                return Set<String>()
        }

        let headerDirs = externalName.map { $0 }
        let customHeaderSearchPaths: Set<String> = headerDirs.fold(basic: { str in Set<String>([str].flatMap { $0 }) },
                                                                   multi: { (result: Set<String>, multi: MultiPlatform<String>) -> Set<String> in
                                                                    return result.union([multi.ios, multi.osx, multi.watchos, multi.tvos].flatMap { $0 })
        })
        return customHeaderSearchPaths
    }

    let customHeaderSearchPaths = Set([podSpec.name]).union(searchPaths(ComposedSpec.composed(child: podSpec, parent: nil)))
        .union(podSpec.subspecs.reduce(Set<String>(), { (result, subspec) in
            result.union(searchPaths(ComposedSpec.composed(child: subspec, parent: ComposedSpec.composed(child: podSpec, parent: nil))))
        })).map { "bazel_support/Headers/Public/\($0)/" }

    customHeaderSearchPaths.forEach(shell.dir)

    // Create a directory structure condusive to <> imports
    // - Get all of the paths matching wild card imports
    // - Put them into the public header directory
    let buildFile = PodBuildFile.with(podSpec: podSpec, buildOptions: buildOptions)
    buildFile.skylarkConvertibles.flatMap { $0 as? RepoTools.ObjcLibrary }
        .flatMap { $0.headers }
        .flatMap { globNode in
            globNode.include.fold(basic: { (patterns: Set<String>?) -> Set<String> in
                let s: Set<String> = Set(patterns.map{ $0.flatMap(podGlob) } ?? [])
                return s
            }, multi: { (set: Set<String>, multi: MultiPlatform<Set<String>>) -> Set<String> in
                let inner: Set<String>? = multi |>
                    MultiPlatform<Set<String>>.lens.viewAll{ Set($0.flatMap(podGlob)) }
                return set.union(inner.denormalize())
            })
        }
        .forEach { globResult in
            customHeaderSearchPaths.forEach { searchPath in
                shell.symLink(from: "\(pwd)/\(globResult)", to: searchPath)
            }
        }
    // Run the compiler
    let buildFileSkylarkCompiler = SkylarkCompiler(buildFile.skylarkConvertibles.flatMap { $0.toSkylark() })
    let buildFileOut = buildFileSkylarkCompiler.run()
    let buildFilePath = URL(fileURLWithPath: "BUILD", relativeTo: URL(fileURLWithPath: pwd))
    shell.write(value: buildFileOut, toPath: buildFilePath)
}

main()
