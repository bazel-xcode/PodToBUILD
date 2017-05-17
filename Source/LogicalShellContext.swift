//
//  LogicalShellContext.swift
//  PodSpecToBUILD
//
//  Created by jerry on 5/9/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

/// Encode commands to a string
private func encode(_ command: String, arguments: [String]) -> String {
    return "\(command)\(arguments.joined(separator: "_"))"
}

typealias ShellInvocation = (String, CommandOutput)

/// Build up a shell invocation.
/// The logical shell simply returns these when someone calls shell.command
/// with a the command and arguments
func MakeShellInvocation(_ command: String, arguments: [String], value standardOutValue: Any = "", exitCode: Int32 = 0) -> ShellInvocation {
	var output = LogicalCommandOutput()
	output.terminationStatus = exitCode

	// Convert the user's input to a data representation
	if let data = standardOutValue as? Data {
		output.standardOutputData = data
	} else {
        if let stringValue = standardOutValue as? String {
            // Convert 
            let stringData = stringValue.data(using: String.Encoding.utf8)!
            output.standardErrorData = stringData
        }
    }
    return (encode(command, arguments: arguments), output)
}

struct LogicalCommandOutput : CommandOutput {
    var standardErrorData = Data()
    var standardOutputData = Data()
    var terminationStatus: Int32 = 0
}

/// LogicalShellContext is a Shell context which is virtualized
/// We don't actually interact with the file system, but execute
/// CommandInvocations
class LogicalShellContext : ShellContext {
    let commandInvocations : [String: CommandOutput]
    private var invokedCommands = [String] ()

    init(commandInvocations: [(String, CommandOutput)]) {
        var values = [String: CommandOutput]()
        commandInvocations.forEach {
            values[$0.0] = $0.1
        }
        self.commandInvocations = values
    }

	func executed(encodedCommand: String) -> Bool {
        print(invokedCommands)
        return invokedCommands.contains(encodedCommand)
    }
    
    func executed(_ command: String, arguments: [String]) -> Bool {
        return invokedCommands.contains(encode(command, arguments: arguments))
    }
    
    func command(_ launchPath: String, arguments: [String]) -> CommandOutput {
        let encoded = encode(launchPath, arguments: arguments)
        print("Execute: \(encoded)\n")
        invokedCommands.append(encoded)
        print("CommandInvocations: \(commandInvocations)\n")
        print("InvokedCommands: \(invokedCommands)\n")
        return commandInvocations[encoded] ?? LogicalCommandOutput()
    }

    func shellOut(_ script: String) -> CommandOutput {
        let encoded = "SHELL " + script
        print("Execute: \(encoded)\n")
        invokedCommands.append(encoded)
        print("CommandInvocations: \(commandInvocations)\n")
        print("InvokedCommands: \(invokedCommands)\n")
        return commandInvocations[encoded] ?? LogicalCommandOutput()
    }

    func dir(_ path: String) {
        invokedCommands.append("DIR:\(path)")
    }

	func symLink(from: String, to: String) {
        let encoded = "symLink from:\(from) to:\(to)"
        invokedCommands.append(encoded)
    }

    func hardLink(from: String, to: String) {
        let encoded = "hardLink from:\(from) to:\(to)"
        invokedCommands.append(encoded)
    }

    func write(value: String, toPath path: URL) {
        let encoded = "write value:\(value) toPath:\(path)"
        invokedCommands.append(encoded)
    }
    
    static func encodeDownload(url: URL, toFile file: String) -> String {
        return "download url:\(url) toFile:\(file)"
    }
    
    func download(url: URL, toFile file: String) -> Bool {
        let encoded = LogicalShellContext.encodeDownload(url: url, toFile: file)
        invokedCommands.append(encoded)
        return true
    }
    
    func tmpdir() -> String {
        let encoded = "create tmpdir"
        invokedCommands.append(encoded)
        return "%TMP%"
    }
}
