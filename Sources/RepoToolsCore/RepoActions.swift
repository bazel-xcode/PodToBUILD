//
//  PodStore.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 5/9/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation
import PodToBUILD
import ObjcSupport

/// The directory where we store things.
/// Only public for testing!
let PodStoreCacheDir = "\(NSHomeDirectory())/.bazel_pod_store/"

enum RepoToolsActionValue: String {
    case fetch
    case initialize = "init"
    case generateWorkspace = "generate_workspace"
}

/// Fetch options are command line options for a given fetch
public struct FetchOptions {
    public let podName: String
    public let url: String
    public let trace: Bool
    public let subDir: String?
}


public struct WorkspaceOptions {
    public let vendorize: Bool = true
    public let trace: Bool
}

/// Parse in Command Line arguments
/// Example: PodName --user_option Opt1

enum CLIArgumentType {
    case bool
    case stringList
    case string
}

public enum SerializedRepoToolsAction {
    case fetch(FetchOptions)
    case initialize(BasicBuildOptions)
    case generateWorkspace(WorkspaceOptions)

    public static func parse(args: [String]) -> SerializedRepoToolsAction {
        guard args.count >= 1 else {
            print("Usage: PodName <init|fetch|generate_workspace> ")
            exit(0)
        }

        // Program, Action
        // or
        // Program, PodName, Action
        let actionStr = args.count == 2 ? args[1] : args[2]
        guard let action = RepoToolsActionValue(rawValue: actionStr) else {
            print("Usage: PodName <init|fetch|generate_workspace> ")
            fatalError()
        }
        switch action {
        case .fetch:
            let fetchOpts = SerializedRepoToolsAction.tryParseFetch(args: args)
            return .fetch(fetchOpts)
        case .initialize:
            let initOpts = SerializedRepoToolsAction.tryParseInit(args: args)
            return .initialize(initOpts)
        case .generateWorkspace:
            let trace = UserDefaults.standard.bool(forKey: "-trace")
            return .generateWorkspace(WorkspaceOptions(trace: trace))
        }
    }

    static func tryParseFetch(args: [String]) -> FetchOptions {
        guard args.count >= 2,
            /// This is a bit insane ( the argument is --url )
            let url = UserDefaults.standard.string(forKey: "-url")
        else {
            print("Usage: PodSpecName <action> --url <URL> --trace <trace>")
            exit(0)
        }

        let name = args[1]
        let trace = UserDefaults.standard.bool(forKey: "-trace")
        let subDir = UserDefaults.standard.string(forKey: "-sub_dir")
        let fetchOpts = FetchOptions(podName: name, url: url, trace: trace,
                                     subDir: subDir)
        return fetchOpts
    }

    static func tryParseInit(args: [String]) -> BasicBuildOptions {
        // First arg is the path, we don't care about it
        // The right most option will be the winner.
        var options: [String: CLIArgumentType] = [
            "--path": .string,
            "--user_option": .stringList,
            "--global_copt": .string,
            "--trace": .bool,
            "--enable_modules": .bool,
            "--generate_module_map": .bool,
            "--generate_header_map": .bool,
            "--vendorize": .bool,
            "--header_visibility": .string,
            "--child_path": .stringList,
        ]

        var idx = 0
        func error() {
            let optsInfo = options.keys.map { $0 }.joined(separator: " ")
            print("Usage: PodspecName " + optsInfo)
            exit(0)
        }

        func nextArg() -> String {
            if idx + 1 < args.count {
                idx += 1
            } else {
                error()
            }
            return args[idx]
        }

        // There is no flag for the podName of the Pod
        let podName = nextArg()
        var parsed = [String: [Any]]()
        _ = nextArg()
        while true {
            idx += 1
            if (idx < args.count) == false {
                break
            }
            let arg = args[idx]
            if let argTy = options[arg] {
                var collected: [Any] = parsed[arg] ?? [Any]()
                let argValue = nextArg()
                switch argTy {
                case .bool:
                    let value = argValue == "true"
                    collected.append(value)
                case .stringList:
                    fallthrough
                case .string:
                    collected.append(argValue)
                }
                parsed[arg] = collected
            } else {
                print("Invalid Arg: \(arg)")
                error()
            }
        }

        return BasicBuildOptions(podName: podName,
                                 path: parsed["--path"]?.first as? String ?? ".",
                                 userOptions: parsed["--user_option"] as? [String] ?? [],
                                 globalCopts: parsed["--global_copt"] as? [String] ?? [],
                                 trace: parsed["--trace"]?.first as? Bool ?? false,
                                 enableModules: parsed["--enable_modules"]?.first as? Bool ?? false,
                                 generateModuleMap: parsed["--generate_module_map"]?.first as? Bool ?? false,
                                 generateHeaderMap: parsed["--generate_header_map"]?.first as? Bool ?? false,
                                 headerVisibility: parsed["--header_visibility"]?.first as? String ?? "",
                                 alwaysSplitRules: false,
                                 vendorize: parsed["--vendorize"]?.first as? Bool ?? true,
                                 childPaths: parsed["--child_path"] as? [String] ?? []
        )
    }
}

/// Helper code compliments of SO:
/// http://stackoverflow.com/questions/25388747/sha256-in-swift
extension String {
    func sha256() -> String {
        if let stringData = self.data(using: .utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }

    private func digest(input: NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }

    private func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)

        var hexString = ""
        for byte in bytes {
            hexString += String(format: "%02x", UInt8(byte))
        }

        return hexString
    }
}

func cacheRoot(forPod pod: String, url: String) -> String {
    return PodStoreCacheDir + pod + "-" + url.sha256() + "/"
}

extension ShellContext {
    func hasDir(_ dirName: String) -> Bool {
        return command("/bin/[", arguments: ["-e", dirName, "]"]).terminationStatus == 0
    }
}

public enum RepoActions {
    /// Initialize a pod repository.
    /// - Get the IPC JSON PodSpec
    /// - Compile a build file based on the PodSpec
    /// - Create a symLinked header structure to support angle bracket includes
    public static func initializeRepository(shell: ShellContext, buildOptions: BuildOptions) {
        let podspecName = CommandLine.arguments[1]
        if buildOptions.path != "." && buildOptions.childPaths.count == 0 {
            // Write an alias BUILD file that points to the source directory
            let visibility = SkylarkNode.functionCall(name: "package",
                arguments: [
                    .named(name: "default_visibility",
                           value: .list([.string("//visibility:public")]))
                ])
            let alias = Alias(name: podspecName,
                actual: "//" + buildOptions.path + ":" + podspecName)
            let acknowledgmentAlias = Alias(name: podspecName + "_acknowledgement",
                actual: "//" + buildOptions.path + ":" + podspecName + "_acknowledgement")
            let compiler = SkylarkCompiler(.lines([
                    visibility.toSkylark(),
                    alias.toSkylark(),
                    acknowledgmentAlias.toSkylark()
            ]))
            shell.write(value: compiler.run(), toPath:
                BazelConstants.buildFileURL())
            return
        }

        initializePodspecDirectory(shell: shell, podspecName: podspecName,
                buildOptions: buildOptions)
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        // Child podspec logic - initializes a child pod, for a given Podspec url
        var childInfoIter = buildOptions.childPaths.makeIterator()
        while let childInfo = childInfoIter.next() {
            let childName = childInfo
            guard let childPath = childInfoIter.next() else {
                fatalError("Invalid path in update_pods.py")
            }
            let childBuildOptions = BasicBuildOptions(
                podName: childName,
                path: childPath,
                userOptions: buildOptions.userOptions,
                globalCopts: buildOptions.globalCopts,
                trace: buildOptions.trace,
                enableModules: buildOptions.enableModules,
                generateModuleMap: buildOptions.generateModuleMap,
                generateHeaderMap: buildOptions.generateHeaderMap,
                headerVisibility: buildOptions.headerVisibility,
                alwaysSplitRules: buildOptions.alwaysSplitRules,
                vendorize: buildOptions.vendorize,
                childPaths: buildOptions.childPaths)
            let absPath = "\(currentDirectoryPath)/../../\(childPath)"
            guard
            FileManager.default.changeCurrentDirectoryPath(
                absPath) else {
                fatalError("Can't change path to child subspec path: " + String(describing: absPath))
            }

            initializePodspecDirectory(shell: shell, podspecName: childName,
                buildOptions: childBuildOptions)
            guard FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath) else {
                fatalError("Can't change path back to original directory after genning subspec")
            }
        }
    }

    private static func initializePodspecDirectory(shell: ShellContext, podspecName: String,buildOptions: BuildOptions) {
        // This uses the current environment's cocoapods installation.
        let whichPod = shell.shellOut("which pod").standardOutputAsString
        if whichPod.isEmpty {
            fatalError("RepoTools requires a cocoapod installation on host")
        }

        // make json data
        let jsonData: Data
        let hasFile: (String) -> Bool = { file in
            // did you know that [ is the name of the binary that tests stuff!
            return shell.command("/bin/[",
                          arguments: ["-e", file, "]"]).terminationStatus == 0
        }

        let workspaceRootPath: String
        if buildOptions.path != "." && buildOptions.childPaths.count == 0 {
            workspaceRootPath = "../..\(buildOptions.path)"
        } else {
            workspaceRootPath =  "."
        }

        let podspecPath = "\(workspaceRootPath)/\(podspecName).podspec"
        if hasFile("\(podspecPath).json") {
            jsonData = shell.command("/bin/cat", arguments: [podspecName + ".podspec.json"]).standardOutputData
        } else if hasFile(podspecPath) {
            let podBin = whichPod.components(separatedBy: "\n")[0]
            let podResult = shell.command(podBin, arguments: ["ipc", "spec", podspecName + ".podspec"])
            guard podResult.terminationStatus == 0 else {
                fatalError("""
                        PodSpec decoding failed \(podResult.terminationStatus)
                        stdout: \(podResult.standardOutputAsString)
                        stderr: \(podResult.standardErrorAsString)
                """)
            }
            jsonData = podResult.standardOutputData
        } else {
            fatalError("Missing podspec ( \(podspecPath) )")
        }

        guard let JSONFile = try? JSONSerialization.jsonObject(with: jsonData, options:
            JSONSerialization.ReadingOptions.allowFragments) as AnyObject,
            let JSONPodspec = JSONFile as? JSONDict
        else {
            fatalError("Invalid JSON Podspec: (look inside \(FileManager.default.currentDirectoryPath))")
        }

        guard let podSpec = try? PodSpec(JSONPodspec: JSONPodspec) else {
            fatalError("Cant read in podspec")
        }

        shell.dir(PodSupportSystemPublicHeaderDir)
        shell.dir(PodSupportDir + "Headers/Private/")
        shell.dir(PodSupportBuidableDir)

        // Create a directory structure condusive to <> imports
        // - Get all of the paths matching wild card imports
        // - Put them into the public header directory
        let buildFile = PodBuildFile.with(podSpec: podSpec, buildOptions: buildOptions)

        // Batch create several symlinks for Pod style includes
        let currentDirectoryPath = FileManager.default.currentDirectoryPath
        if buildOptions.generateHeaderMap == false {
            let objcLibraries: [ObjcLibrary] = buildFile.skylarkConvertibles.compactMap { $0 as? ObjcLibrary }
            objcLibraries.forEach { lib -> Void in
                _ = lib.headers.zip(lib.headerName).map {
                    attrTuple -> Set<String>? in
                    defer {
                        guard FileManager.default.changeCurrentDirectoryPath(currentDirectoryPath) else {
                            fatalError("Can't change path back to original directory")
                        }
                    }
                    guard let headers = attrTuple.first else {
                        return nil
                    }
                    // Note: this is going to evaluate the glob, this needs to
                    // happen _inside_ of the root directory.
                    let globResults = headers.sourcesOnDisk()

                    let searchPath = attrTuple.second ?? lib.externalName
                    let linkPath = PodSupportSystemPublicHeaderDir + searchPath
                    shell.dir(linkPath)
                    guard FileManager.default.changeCurrentDirectoryPath(linkPath) else {
                        print("WARNING: Can't change path while creating symlink: " + linkPath)
                        return nil
                    }
                    globResults.forEach { globResult in
                        // i.e. pod_support/Headers/Public/__POD_NAME__
                        let from = "../../../../\(globResult)"
                        let to = String(globResult.split(separator: "/").last!)
                        print("Symlink: \(from) \(to)")
                        shell.symLink(from: from, to: to)
                    }
                    return globResults
                }
            }
        }

        // Write out contents of PodSupportBuildableDir

        // Write out the acknowledgement entry plist
        let entry = RenderAcknowledgmentEntry(entry: AcknowledgmentEntry(forPodspec: podSpec))
        let acknowledgementFilePath = URL(fileURLWithPath: PodSupportBuidableDir + "acknowledgement.plist")
        shell.write(value: entry, toPath: acknowledgementFilePath)

        // assume _PATH_TO_SOME/bin/RepoTools
        let assetRoot = RepoActions.assetRoot(buildOptions: buildOptions)

        shell.symLink(from: "\(assetRoot)/support.BUILD",
            to: "\(PodSupportBuidableDir)/\(BazelConstants.buildFilePath)")

        // Write the root BUILD file
        let buildFileSkylarkCompiler = SkylarkCompiler(buildFile.toSkylark())
        let buildFileOut = buildFileSkylarkCompiler.run()

        // When there is a "child" podspec adjacent to a parent, concat the
        // "child" BUILD file into the parents
        if PodBuildFile.shouldAssimilate(buildOptions: buildOptions) {
            let fileUpdater = try! FileHandle(forWritingTo:
                BazelConstants.buildFileURL())
            fileUpdater.seekToEndOfFile()
            fileUpdater.write("\n".data(using: .utf8)!)
            if let data = buildFileOut.data(using: .utf8) {
                fileUpdater.write(data)
            }
            fileUpdater.closeFile()
        } else {
            shell.write(value: buildFileOut, toPath:
                BazelConstants.buildFileURL())
        }
    }

    // Assume the directory structure relative to the pod root
    private static func assetRoot(buildOptions: BuildOptions) -> String {
        if buildOptions.path ==  "." {
            return "../../../Vendor/rules_pods/BazelExtensions"
        }
        let nestingDepth = buildOptions.path.split(separator: "/").count
        let relativePathToWorkspace = (0..<nestingDepth).map { _ in ".." }.joined(separator: "/") 
        return "\(relativePathToWorkspace)/../Vendor/rules_pods/BazelExtensions"
    }

    /// Generates a workspace from a Podfile.lock
    public static func generateWorkspace(shell: ShellContext, workspaceOptions: WorkspaceOptions) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: "Podfile.lock"))
            let lockfile = try Lockfile(data: data)
            let workspace = try PodsWorkspace(lockfile: lockfile, shell: shell)
            let compiler = SkylarkCompiler(workspace.toSkylark())
            print("Dict", compiler.run())
        } catch {
            print("Error", error)
        }
    }

    /// Fetch pods from urls.
    /// - Fetch the URL
    /// - Store pod artifacts in the users home directory to prevent
    ///   redundant downloads across bazel repos and cleans.
    /// - Export the requested pod directory into the working directory
    ///
    /// Notes:
    /// We can't use bazel's unarchiving mechanism because it's validation is
    /// incompatible with many pods.
    /// Operations should be atomic
    public static func fetch(shell: ShellContext, fetchOptions: FetchOptions) {
        let podName = fetchOptions.podName
        let urlString = fetchOptions.url
        _ = shell.command(CommandBinary.mkdir, arguments: ["-p", PodStoreCacheDir])

        // Cache Hit
        let podCacheRoot = escape(cacheRoot(forPod: podName, url: urlString))
        if shell.hasDir(podCacheRoot) {
            exportArchive(shell: shell, podCacheRoot: podCacheRoot,
                          fetchOptions: fetchOptions)
            return
        }

        let downloadsDir = shell.tmpdir()
        let url = NSURL(string: urlString)!
        let fileName = url.lastPathComponent!
        let download = downloadsDir + "/" + podName + "-" + fileName
        guard let wwwUrl = NSURL(string: urlString).map({ $0 as URL }),
            shell.download(url: wwwUrl, toFile: download) else {
            fatalError("Download of \(podName) failed")
        }

        // Extract the downloaded archive
        let extractDir = shell.tmpdir()
        func extract() -> CommandOutput {
            let lowercasedFileName = fileName.lowercased()
            if lowercasedFileName.hasSuffix("zip") {
                return shell.command(CommandBinary.sh, arguments: [
                    "-c",
                    unzipTransaction(
                        rootDir: extractDir,
                        fileName: escape(download)
                    ),
                ])
            } else if
                lowercasedFileName.hasSuffix("tar")
                || lowercasedFileName.hasSuffix("tar.gz")
                || lowercasedFileName.hasSuffix("tgz")
            {
                return shell.command(CommandBinary.sh, arguments: [
                    "-c",
                    untarTransaction(
                        rootDir: extractDir,
                        fileName: escape(download)
                    ),
                ])
            }
            fatalError("Cannot extract files other than .zip, .tar, .tar.gz, or .tgz. Got \(lowercasedFileName)")
        }

        assertCommandOutput(extract(), message: "Extraction of \(podName) failed")

        // Save artifacts to cache root
        let export = shell.command("/bin/sh", arguments: [
            "-c",
            "mkdir -p " + extractDir + " && " +
                "cd " + extractDir + " && " +
                "mkdir -p " + podCacheRoot + " && " +
                "mv OUT/* " + podCacheRoot,
        ])
        _ = shell.command(CommandBinary.rm, arguments: ["-rf", extractDir])
        if export.terminationStatus != 0 {
            _ = shell.command(CommandBinary.rm, arguments: ["-rf", podCacheRoot])
            fatalError("Filesystem is in an invalid state")
        }
        exportArchive(shell: shell, podCacheRoot: podCacheRoot,
                      fetchOptions: fetchOptions)
    }

    static func exportArchive(shell: ShellContext, podCacheRoot: String,
                              fetchOptions: FetchOptions) {
        let fileManager = FileManager.default
        let path: String
        let fetchOptionsSubDir = fetchOptions.subDir?.isEmpty == false ?
            fetchOptions.subDir : nil
        if let subDir = fetchOptionsSubDir ?? githubMagicSubDir(fetchOptions: fetchOptions) {
            path = podCacheRoot + subDir
        } else {
            path = podCacheRoot
        }

        _ = shell.command(CommandBinary.ditto, arguments: [path, fileManager.currentDirectoryPath])
    }

    static func githubMagicSubDir(fetchOptions: FetchOptions) -> String? {
        // Github export sugar
        // "https://github.com/facebook/KVOController/archive/v1.1.0.zip"
        // Ends up:
        // v1.1.0.zip
        // After unzipping
        // KVOController-1.1.0
        let testURL = fetchOptions.url.lowercased()
        guard testURL.contains("github") else { return nil }
        let components = testURL.components(separatedBy: "/")
        guard components[components.count - 2] == "archive" else {
            return nil
        }
        var fileName = components[components.count - 1].replacingOccurrences(of: ".zip", with: "")

        // Github tagging
        let unicode = fileName.unicodeScalars
        let secondUnicode = unicode[unicode.index(unicode.startIndex, offsetBy:
                1)]
        if fileName.contains(".")
            && fileName[fileName.startIndex] == "v"
            && CharacterSet.decimalDigits.contains(secondUnicode) {
            fileName = String(fileName[
                fileName.index(fileName.startIndex, offsetBy: 1)...])
        }
        let magicDir = components[components.count - 3] + "-" + fileName
        return magicDir
    }

    static func assertCommandOutput(_ output: CommandOutput, message: String) {
        if output.terminationStatus != 0 {
            fatalError(message)
        }
    }

    // Unzip the entire contents into OUT
    static func unzipTransaction(rootDir: String, fileName: String) -> String {
        return "mkdir -p " + rootDir + " && " +
            "cd " + rootDir + " && " +
            "unzip -d OUT " + fileName + " > /dev/null && " +
            "rm -rf " + fileName
    }

    static func untarTransaction(rootDir: String, fileName: String) -> String {
        return "mkdir -p " + rootDir + " && " +
            "cd " + rootDir + " && " +
            "mkdir -p OUT && " +
            "tar -xzvf " + fileName + " -C OUT > /dev/null 2>&1 && " +
            "rm -rf " + fileName
    }
}

