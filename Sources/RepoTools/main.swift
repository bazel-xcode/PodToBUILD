//
//  main.swift
//  RepoTools
//
//  Created by Jerry Marino on 4/17/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation
import PodToBUILD
import ObjcSupport
import RepoToolsCore

protocol HelpCommandOutput {
    static func printHelp() -> String
}

enum FlagOptions: String {
    case version = "version"
    case help = "help"

    func needsArgument() -> Bool {
        switch self {
        case .version: return false
        case .help: return false
        }
    }
}

extension FlagOptions: HelpCommandOutput {
    internal static func printHelp() -> String {
        return [
            "    --\(FlagOptions.version.rawValue) - Show version number and exit",
            "    --\(FlagOptions.help.rawValue) - Show this text and exit"
            ].joined(separator: "\n")
    }
}

func parseFlag(arguments: [String]) -> ([FlagOptions: String], [String])? {

    guard let someFlag = (arguments.first.map {
        $0.components(separatedBy: "=")[0]
        }.flatMap { arg in
            arg.hasPrefix("--") ? arg.trimmingCharacters(in: CharacterSet(charactersIn: "-")) : nil
    }) else { return nil }

    guard let nextFlag = FlagOptions(rawValue: someFlag) else {
        print("Error: Unexpected flag \(someFlag)")
        handleHelpCommand()
        exit(1)
    }

    if nextFlag.needsArgument() {
        let arg = arguments[0]
        if arg.contains("=") {
            let flagComponents = arg.components(separatedBy: "=")
            assert(flagComponents.count == 2, "Error: Invalid flag declaration: Too many = signs")
            return (
                [nextFlag: flagComponents[1]],
                Array(arguments[1..<arguments.count])
            )
        } else {
            assert(arguments.count >= 2, "Error: Invalid flag declaration: No value for \(nextFlag.rawValue)")
            return (
                [nextFlag: arguments[1]],
                Array(arguments[2..<arguments.count])
            )
        }
    } else {
        return (
            [nextFlag: ""],
            Array(arguments[1..<arguments.count])
        )
    }
}

func parseFlags(fromArguments arguments: [String]) -> ([FlagOptions: String], [String]) {
    guard !arguments.isEmpty else { return ([:], arguments) }

    if let (flagDict, remainingArgs) = parseFlag(arguments: arguments) {
        if remainingArgs.count > 0 {
            // recursive
            let (remainingFlags, extraArgs) = parseFlags(fromArguments: remainingArgs)
            if remainingFlags.count == 0 {
                return (flagDict, extraArgs)
            }
            var mutableFlags = flagDict
            _ = remainingFlags.map { key, value in mutableFlags.updateValue(value, forKey: key) }
            return (mutableFlags, extraArgs)
        } else {
            return (flagDict, remainingArgs)
        }
    }
    return ([:], arguments)
}



public struct Version {
    public let value: String

    public static let current = Version(value: "__PODTOBUILD_VERSION__")
}


func handleHelpCommand() {
    let helpDocs = [
        "Usage:",
        "    $ RepoTools [options] <init|fetch> somePodspec.json",
        "",
        "Options:",
        "\(FlagOptions.printHelp())"
        ].joined(separator: "\n")

    print(helpDocs)
}


func handleVersionCommand() {
    print(Version.current.value)
}

func main() {
    let arguments = ProcessInfo.processInfo.arguments.dropFirst() // Drop executable name
    let (flags, args) = parseFlags(fromArguments: Array(arguments))

    if flags[.help] != nil {
        handleHelpCommand()
        return
    }

    if flags[.version] != nil{
        handleVersionCommand()
        return
    }


    guard args.count > 1 else {
        print("Error: Missing path to JSON Podspec or <init | fetch>")
        handleHelpCommand()
        return
    }



    _ = CrashReporter()
    let action = SerializedRepoToolsAction.parse(args: CommandLine.arguments)
    switch action {
    case .initialize(let opts):
        let shell = SystemShellContext(trace: opts.trace)
        RepoActions.initializeRepository(shell: shell, buildOptions: opts)
    case .fetch(let opts):
        let shell = SystemShellContext(trace: opts.trace)
        RepoActions.fetch(shell: shell, fetchOptions: opts)
       break
    }
}

main()
