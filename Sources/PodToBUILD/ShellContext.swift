//
//  ShellContext.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 5/9/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import Foundation
import ObjcSupport

/// The output of a ShellContext command
public protocol CommandOutput {
    var standardErrorData: Data { get }
    var standardOutputData: Data { get }
    var terminationStatus: Int32 { get }
}

public struct CommandBinary {
    public static let mkdir = "/bin/mkdir"
    public static let mktemp = "/usr/bin/mktemp"
    public static let ln = "/bin/ln"
    public static let pwd = "/bin/pwd"
    public static let sh = "/bin/sh"
    public static let ditto = "/usr/bin/ditto"
    public static let rm = "/bin/rm"
}

extension CommandOutput {
    /// Return Standard Output as a String
    public var standardOutputAsString : String {
        return String(data: standardOutputData, encoding: String.Encoding.utf8) ?? ""
    }
    
    public var standardErrorAsString : String {
        return String(data: standardErrorData, encoding: String.Encoding.utf8) ?? ""
    }
}

/// Multiply seconds by minutes by 4
let FOUR_HOURS_TIME_CONSTANT = (60.0 * 60.0 * 4.0)

/// Shell Contex is a context to interact with the users system
/// All interaction with the the system should go through this
/// layer, so that it is auditable, traceable, and testable
public protocol ShellContext {
    @discardableResult func command(_ launchPath: String, arguments: [String]) -> CommandOutput

    @discardableResult func shellOut(_ script: String) -> CommandOutput

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
    let path: String?
    let arguments: [String]

    init(command: String, arguments: [String], timeout: CFTimeInterval, cwd:
            String? = nil) {
        self.command = command
        self.arguments = arguments
        self.timeout = timeout
        self.path = cwd
    }

    /// Create a task with a script and timeout
    /// By default, it runs under bash for the current path.
    public static func with(script: String, timeout: Double, cwd: String? = nil) -> ShellTask {
        let path = ProcessInfo.processInfo.environment["PATH"]!
        let script = "PATH=%\(path) /bin/sh -c '\(script)'"
        return ShellTask(command: "/bin/bash", arguments: ["-c", script],
                timeout: timeout, cwd: cwd)
    }

    override var description: String {
        return "ShellTask: " + command + " " + arguments.joined(separator: " ")
    }
    override var debugDescription : String {
        return description
    }

    class RunLoopContext {
        var cancelTerminationStatus: Int32? = nil
        var process: Process
        init (process: Process) {
            self.process = process
        }
    }

    /// Launch a task and get the output
    func launch() -> CommandOutput {
        let process = Process()

        let runLoopContext = RunLoopContext(process: process)
        // Setup a timer.
        // When this timer ends, we smoke the process.
        var runLoopCtx =  CFRunLoopTimerContext()
        runLoopCtx.info = unsafeBitCast(runLoopContext, to: UnsafeMutableRawPointer.self)
        let runLoopCB: CoreFoundation.CFRunLoopTimerCallBack = {
            (c: CFRunLoopTimer?, ctx: UnsafeMutableRawPointer?)  in
            let ctx = unsafeBitCast(ctx, to: RunLoopContext.self)
            let _ = tryBlock {
                ctx.process.terminate()
            }
            // Try to get the termination status, and assign it to 43 if it throws
            var status: Int32 = 0
            let _ = tryBlock {
                status = ctx.process.terminationStatus
            }
            ctx.cancelTerminationStatus = status != 0 ? status : 43
            CFRunLoopStop(RunLoop.main.getCFRunLoop())
        }

        let timer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent() + timeout, 0, 0, 0, runLoopCB, &runLoopCtx)

        let currentLoop = RunLoop.main.getCFRunLoop()
        CFRunLoopAddTimer(currentLoop, timer, CFRunLoopMode.defaultMode)
        
        var didTerminateStatus: Int32? = nil
        let taskObserver = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification, object: process, queue: OperationQueue()) {
            _ in
            didTerminateStatus = process.terminationStatus
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
        if let cwd = path {
            if #available(OSX 10.13, *) {
                process.currentDirectoryURL = URL(fileURLWithPath: cwd)
            } else {
                // Fallback on earlier versions
                process.currentDirectoryPath  = cwd
            }
        }
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
                               terminationStatus: didTerminateStatus
                               ?? runLoopContext.cancelTerminationStatus ?? 44)
    }
}

/// SystemShellContext is a shell context that mutates the user's system
/// All mutations may be logged
public struct SystemShellContext : ShellContext {
    func command(_ launchPath: String, arguments: [String]) -> (String, CommandOutput) {
        let data = startShellAndWait(launchPath, arguments: arguments)
        let string = String(data: data.standardOutputData, encoding: String.Encoding.utf8) ?? ""
        return (string, data)
    }

    private let trace: Bool

    public init(trace: Bool = false) {
        // Warning this disables buffering for all of the output
        setbuf(__stdoutp, nil)

        self.trace = trace
    }

    public func command(_ launchPath: String, arguments: [String] = [String]()) -> CommandOutput {
        return startShellAndWait(launchPath, arguments: arguments)
    }

    @discardableResult public func shellOut(_ script: String) -> CommandOutput {
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

    public func dir(_ path: String) {
        let dir = command(CommandBinary.pwd).standardOutputAsString.components(separatedBy: "\n")[0]
        let relativedir = escape("\(dir)/\(path)")
        log("DIR\(relativedir)")
        let status = command(CommandBinary.mkdir, arguments: ["-p", relativedir]).terminationStatus
        log("DIR STATUS \(status)")
    }

    public func hardLink(from: String, to: String) {
        log("LINK FROM \(from) to \(to)")
        let status = command("/bin/ln", arguments: ["", escape(from), escape(to)]).terminationStatus
        log("LINK STATUS \(status)")
    }

    public func symLink(from: String, to: String) {
        log("LINK FROM \(from) to \(to)")
        do {
            try FileManager.default.createSymbolicLink(atPath: to, withDestinationPath: from)
            print("LINK SUCCESS")
        } catch {
            print("LINK ERROR: ", error.localizedDescription)
        }
    }

    public func write(value: String, toPath path: URL) {
        log("WRITE \(value) TO \(path)")
        try? value.write(to: path, atomically: false, encoding: String.Encoding.utf8)
    }
    
    public func download(url: URL, toFile file: String) -> Bool {
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
    
    public func tmpdir() -> String {
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
