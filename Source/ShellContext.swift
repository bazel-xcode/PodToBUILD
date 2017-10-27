//
//  ShellContext.swift
//  PodSpecToBUILD
//
//  Created by jerry on 5/9/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation

/// The output of a ShellContext command
public protocol CommandOutput {
    var standardErrorData: Data { get }
    var standardOutputData: Data { get }
    var terminationStatus: Int32 { get }
}

struct CommandBinary {
    static let mkdir = "/bin/mkdir"
    static let mktemp = "/usr/bin/mktemp"
    static let ln = "/bin/ln"
    static let pwd = "/bin/pwd"
    static let sh = "/bin/sh"
    static let ditto = "/usr/bin/ditto"
    static let rm = "/bin/rm"
}

extension CommandOutput {
    /// Return Standard Output as a String
    var standardOutputAsString : String {
        return String(data: standardOutputData, encoding: String.Encoding.utf8) ?? ""
    }
    
    var standardErrorAsString : String {
        return String(data: standardErrorData, encoding: String.Encoding.utf8) ?? ""
    }
}

/// Multiply seconds by minutes by 4
let FOUR_HOURS_TIME_CONSTANT = (60.0 * 60.0 * 4.0)

/// Shell Contex is a context to interact with the users system
/// All interaction with the the system should go through this
/// layer, so that it is auditable, traceable, and testable
public protocol ShellContext {
    func command(_ launchPath: String, arguments: [String]) -> CommandOutput

    func shellOut(_ script: String) -> CommandOutput

    func dir(_ path: String)

    func hardLink(from: String, to: String)

    func symLink(from: String, to: String)
    
    func write(value: String, toPath path: URL)
    
    func download(url: URL, toFile: String) -> Bool
    
    func tmpdir() -> String
}

/// Escape paths
public func escape(_ string: String) -> String {
    return string.replacingOccurrences(of: "\\", with: "\\\\", options: .literal, range: nil)
}

let kTaskDidFinishNotificationName = NSNotification.Name(rawValue: "kTaskDidFinishNotificationName")

private struct ShellTaskResult : CommandOutput {
    let standardErrorData: Data
    let standardOutputData: Data
    let terminationStatus: Int32
}

/// Shell task runs a given command and waits
/// for it to terminate or timeout
class ShellTask : NSObject {
    let timeout: CFTimeInterval
    let command: String
    let arguments: [String]

    init(command: String, arguments: [String], timeout: CFTimeInterval) {
        self.command = command
        self.arguments = arguments
        self.timeout = timeout
    }

    /// Create a task with a script and timeout
    /// By default, it runs under bash for the current path.
    public static func with(script: String, timeout: Double) -> ShellTask {
        let path = ProcessInfo.processInfo.environment["PATH"]!
        let script = "PATH=%\(path) /bin/sh -c '\(script)'"
        return ShellTask(command: "/bin/bash", arguments: ["-c", script], timeout: timeout)
    }

    override var description: String {
        return "ShellTask: " + command + " " + arguments.joined(separator: " ")
    }
    override var debugDescription : String {
        return description
    }

    /// Launch a task and get the output
    func launch() -> CommandOutput {
        let process = Process()
        
        // Setup a timer.
        // When this timer ends, we smoke the process.
        var runLoopCtx =  CFRunLoopTimerContext()
        runLoopCtx.info = unsafeBitCast(process, to: UnsafeMutableRawPointer.self)
        let runLoopCB: CoreFoundation.CFRunLoopTimerCallBack = {
            (c: CFRunLoopTimer?, ctx: UnsafeMutableRawPointer?)  in
            let process = unsafeBitCast(ctx, to: Process.self)
            process.terminate()
            CFRunLoopStop(RunLoop.main.getCFRunLoop())
        }

        let timer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent() + timeout, 0, 0, 0, runLoopCB, &runLoopCtx)

        let currentLoop = RunLoop.main.getCFRunLoop()
        CFRunLoopAddTimer(currentLoop, timer, CFRunLoopMode.defaultMode)
        
        let taskObserver = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: process, queue: OperationQueue()) {
            _ in
            CFRunLoopStop(currentLoop)
        }
        
        // Setup the process.
        let stdout = Pipe()
        let stderr  = Pipe()
        var env = ProcessInfo.processInfo.environment
        env["LANG"] = "en_US.UTF-8"
        process.environment = env
        process.standardOutput = stdout
        process.standardError = stderr
        process.launchPath = command
        process.arguments = arguments
        let exception = tryBlock {
          process.launch()
          CFRunLoopRun()
        }
        
        CFRunLoopRemoveTimer(currentLoop, timer, CFRunLoopMode.defaultMode)
        NotificationCenter.default.removeObserver(taskObserver)

        if exception != nil {
            // Attempt to read standard output
            let standardErrorData = stderr.fileHandleForReading.readDataToEndOfFile()
            return ShellTaskResult(standardErrorData: standardErrorData,
                                   standardOutputData: Data(),
                                   terminationStatus: 42)
        }

        let standardOutputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let standardErrorData = stderr.fileHandleForReading.readDataToEndOfFile()
        return ShellTaskResult(standardErrorData: standardErrorData,
                               standardOutputData: standardOutputData,
                               terminationStatus: process.terminationStatus)
    }
}

/// SystemShellContext is a shell context that mutates the user's system
/// All mutations may be logged
struct SystemShellContext : ShellContext {
    func command(_ launchPath: String, arguments: [String]) -> (String, CommandOutput) {
        let data = startShellAndWait(launchPath, arguments: arguments)
        let string = String(data: data.standardOutputData, encoding: String.Encoding.utf8) ?? ""
        return (string, data)
    }

    private let trace: Bool

    init(trace: Bool = false) {
        // Warning this disables buffering for all of the output
        setbuf(__stdoutp, nil)

        self.trace = trace
    }

    func command(_ launchPath: String, arguments: [String] = [String]()) -> CommandOutput {
        return startShellAndWait(launchPath, arguments: arguments)
    }

    func shellOut(_ script: String) -> CommandOutput {
        log("SHELL:\(script)")
        let task = ShellTask.with(script: script,
                                  timeout: FOUR_HOURS_TIME_CONSTANT)
        let result = task.launch()
        let stderrData = result.standardErrorData
        let stdoutData = result.standardOutputData
        let statusCode = result.terminationStatus
        log("PIPE OUTPUT\(script) stderr:\(readData(stderrData))  stdout:\(readData(stdoutData)) code:\(statusCode )")
        return result
    }

    func dir(_ path: String) {
        let dir = command(CommandBinary.pwd).standardOutputAsString.components(separatedBy: "\n")[0]
        let relativedir = escape("\(dir)/\(path)")
        log("DIR\(relativedir)")
        let status = command(CommandBinary.mkdir, arguments: ["-p", relativedir]).terminationStatus
        log("DIR STATUS \(status)")
    }

    func hardLink(from: String, to: String) {
        log("LINK FROM \(from) to \(to)")
        let status = command("/bin/ln", arguments: ["", escape(from), escape(to)]).terminationStatus
        log("LINK STATUS \(status)")
    }

    func symLink(from: String, to: String) {
        log("LINK FROM \(from) to \(to)")
        let status = command("/bin/ln", arguments: ["-s", escape(from), escape(to)]).terminationStatus
        log("LINK STATUS \(status)")
    }
    
    func write(value: String, toPath path: URL) {
        log("WRITE \(value) TO \(path)")
        try? value.write(to: path, atomically: false, encoding: String.Encoding.utf8)
    }
    
    func download(url: URL, toFile file: String) -> Bool {
        log("DOWNLOAD \(url) TO \(file)")
        guard let fileData = NSData(contentsOf: url) else {
            return false
        }
        let err: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
        NSFileCoordinator().coordinate(writingItemAt: url,
                                       options: NSFileCoordinator.WritingOptions.forReplacing,
                                       error: err) { (fileURL) in
                FileManager.default.createFile(atPath: file, contents: fileData as Data, attributes: nil)
        }
        return (err == nil)
    }
    
    func tmpdir() -> String {
        log("CREATE TMPDIR")
        return command(CommandBinary.mktemp, arguments: ["-d"]).standardOutputAsString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    // MARK: - Private

    // Start a shell and wait for the result
    // @note we use UTF-8 here as the default language and the current env
    private func startShellAndWait(_ launchPath: String, arguments: [String] =
            [String]()) -> CommandOutput {
        log("COMMAND:\(launchPath) \(arguments)")
        let task = ShellTask(command: launchPath, arguments: arguments,
                timeout: FOUR_HOURS_TIME_CONSTANT)
        let result = task.launch()
        let stderrData = result.standardErrorData
        let stdoutData = result.standardOutputData
        let statusCode = result.terminationStatus
        log("PIPE OUTPUT\(launchPath) \(arguments) stderr:\(readData(stderrData))  stdout:\(readData(stdoutData)) code:\(statusCode )")
        return result
    }

    private func readData(_ data: Data) -> String {
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }

    private func log(_ args: Any...) {
        if trace {
            print(args.map { "\($0)" }.joined(separator: " ") )
        }
    }
}
