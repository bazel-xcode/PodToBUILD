//
//  PodStore.swift
//  PodSpecToBUILD
//
//  Created by jerry on 5/9/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

/// The directory where we store things.
/// Only public for testing!
let PodStoreCacheDir = "\(NSHomeDirectory())/.bazel_pod_store/"

enum RepoToolsActionValue : String {
    case fetch
    case initialize = "init"
}

/// Fetch options are command line options for a given fetch
public struct FetchOptions {
    let podName: String
    let url: String
    let trace: Bool
    let subDir: String?
}

/// Parse in Command Line arguments
/// Example: PodName --user_option Opt1
public struct BasicBuildOptions : BuildOptions {
    public let podName: String
    public let userOptions: [String]
    public let globalCopts: [String]
    public let trace: Bool

    public init(podName: String, userOptions: [String], globalCopts: [String], trace: Bool) {
        self.podName = podName
        self.userOptions = userOptions
        self.globalCopts = globalCopts
        self.trace = trace
    }
}

enum SerializedRepoToolsAction {
    case fetch(FetchOptions)
    case initialize(BasicBuildOptions)

    static func parse(args: [String]) -> SerializedRepoToolsAction {
        guard args.count >= 2 else {
            print("Usage: PodName <init|fetch> ")
            exit(0)
        }
        // Program, PodName, Action
        let action = RepoToolsActionValue(rawValue: args[2])!
        switch action {
        case .fetch:
            let fetchOpts = SerializedRepoToolsAction.tryParseFetch(args: args)
            return .fetch(fetchOpts)
        case .initialize:
            let initOpts = SerializedRepoToolsAction.tryParseInit(args: args)
            return .initialize(initOpts)
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
        var multiOptions = [
            "--user_option" : Set<String>(),
            "--global_copt" : Set<String>(),
            "--trace" : Set<String>()
        ]

        var idx = 0
        func error() {
            let optsInfo = multiOptions.keys.map{ $0 }.joined(separator: " ")
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
        _ = nextArg()
        while (true) {
            idx += 1
            if (idx < args.count) == false {
                break
            }
            if let _ = multiOptions[args[idx]] {
                multiOptions[args[idx]]!.insert(nextArg())
            } else {
                error()
            }
        }
        
        return BasicBuildOptions(podName: podName,
                                 userOptions: Array(multiOptions["--user_option"]!),
                                 globalCopts: Array(multiOptions["--global_copt"]!),
                                 trace: multiOptions["--trace"] != nil
        )
    }
}

/// Helper code compliments of SO:
/// http://stackoverflow.com/questions/25388747/sha256-in-swift
extension String {
    func sha256() -> String{
        if let stringData = self.data(using: .utf8) {
            return hexStringFromData(input: digest(input: stringData as NSData))
        }
        return ""
    }
    
    private func digest(input : NSData) -> NSData {
        let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
        var hash = [UInt8](repeating: 0, count: digestLength)
        CC_SHA256(input.bytes, UInt32(input.length), &hash)
        return NSData(bytes: hash, length: digestLength)
    }
    
    private  func hexStringFromData(input: NSData) -> String {
        var bytes = [UInt8](repeating: 0, count: input.length)
        input.getBytes(&bytes, length: input.length)
        
        var hexString = ""
        for byte in bytes {
            hexString += String(format:"%02x", UInt8(byte))
        }
        
        return hexString
    }
}

func cacheRoot(forPod pod: String, url: String) -> String{
    return PodStoreCacheDir + pod + "-" + url.sha256() + "/"
}

extension ShellContext {
    func hasDir(_ dirName: String) -> Bool {
        return command("/bin/[", arguments: ["-e", dirName, "]"]).terminationStatus == 0
    }   
}

enum RepoActions {
    /// Initialize a pod repository.
    /// - Get the IPC JSON PodSpec
    /// - Compile a build file based on the PodSpec
    /// - Create a symlinked header structure to support angle bracket includes
    static func initializeRepository(shell: ShellContext, buildOptions: BasicBuildOptions) {
        let whichPod = shell.command("/bin/bash", arguments: ["-l", "-c", "which pod"]).standardOutputAsString
        if whichPod.isEmpty {
            fatalError("RepoTools requires a cocoapod installation on host")
        }
        let podspecName = CommandLine.arguments[1]
        let pwd = shell.command(CommandBinary.pwd, arguments: [String]()).standardOutputAsString.components(separatedBy: "\n")[0]
        
        // make json data
        let jsonData: Data;
        let hasFile: (String) -> Bool = { file in
            // did you know that [ is the name of the binary that tests stuff!
            shell.command("/bin/[",
                          arguments: ["-e", file, "]"]).terminationStatus == 0
        }
        let hasPodspec: () -> Bool = { hasFile(podspecName + ".podspec") }
        let hasPodspecJson: () -> Bool = { hasFile(podspecName + ".podspec.json") }
        
        if hasPodspec() {
            let podBin = whichPod.components(separatedBy: "\n")[0]
            jsonData = shell.command(podBin, arguments: ["ipc", "spec", podspecName + ".podspec"]).standardOutputData
        } else if hasPodspecJson() {
            jsonData = shell.command("/bin/cat", arguments: [podspecName + ".podspec.json"]).standardOutputData
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
        buildFile.skylarkConvertibles.flatMap { $0 as? ObjcLibrary }
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
    static func fetch(shell: ShellContext, fetchOptions: FetchOptions) {
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
        let url  = NSURL(fileURLWithPath: urlString)
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
                return shell.command(CommandBinary.sh, arguments: ["-c",
                        unzipTransaction(
                            rootDir: extractDir,
                            fileName: escape(download)
                            )
                ])
            } else if lowercasedFileName.hasSuffix("tar.gz") {
                return shell.command(CommandBinary.sh, arguments: ["-c",
                        untarTransaction(
                            rootDir: extractDir,
                            fileName: escape(download)
                            )
                ])
            }
            fatalError("Cannot extract files other than .zip or .tar")
        }

        assertCommandOutput(extract(), message: "Extraction of \(podName) failed")

        // Save artifacts to cache root
        let export = shell.command("/bin/sh", arguments: ["-c",
                        "mkdir -p " + extractDir + " && " +
                        "cd " + extractDir + " && " + 
                        "mkdir -p " + podCacheRoot + " && " +
                        "mv OUT/* " + podCacheRoot
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
            && CharacterSet.decimalDigits.contains(secondUnicode)  {
            fileName = fileName.substring(from:
                    fileName.index(fileName.startIndex, offsetBy: 1))
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
            "tar -xzvf " + fileName + " -C OUT > /dev/null && " +
            "rm -rf " + fileName
    }
}
