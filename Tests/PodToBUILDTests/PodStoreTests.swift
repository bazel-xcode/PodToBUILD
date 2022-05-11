//
//  PodStoreTests.swift
//  PodStoreTests
//
//  Created by Jerry Marino on 5/9/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
//

import XCTest
@testable import PodToBUILD
@testable import RepoToolsCore

let testPodName = "Foo"

let fetchOpts = FetchOptions(
    podName: testPodName,
    url: "http://pinner.com/foo.zip",
    trace: false,
    subDir: nil,
    revision: nil)

class PodStoreTests: XCTestCase {

    var downloads: String {
        return "%TMP%"
    }
    
    var extractDir: String {
        return "%TMP%"
    }
    
	var downloadPath: String {
        return downloads + "/" + testPodName + "-" + "foo.zip"
    }   
        
    var hasDir: ShellInvocation {
        return MakeShellInvocation("/bin/[", arguments: ["-e", cacheRoot(forPod:
                testPodName, url: "http://pinner.com/foo.zip"), "]"], exitCode: 1)
    }

    var podCacheRoot: String {
		return cacheRoot(forPod: testPodName, url: "http://pinner.com/foo.zip")
	}

	func testURLDownloading() {
        let shell = LogicalShellContext(commandInvocations: [
            hasDir
            ])
        RepoActions.fetch(shell: shell, fetchOptions: fetchOpts)
        XCTAssertTrue(
            shell.executed(encodedCommand:
                LogicalShellContext.encodeDownload(url: URL(string: fetchOpts.url)!, toFile: downloadPath)
            )
        )
    }

    func testGitCommitDownloading() {
        let shell = SystemShellContext()
        let gitFetchOptions = FetchOptions(
            podName: "Kingfisher",
            url: "git@github.com:onevcat/Kingfisher.git",
            trace: false,
            subDir: nil,
            revision: "commit:59eb199")
        RepoActions.fetch(shell: shell, fetchOptions: gitFetchOptions)
        let cacheDir = GitDownloader(options: gitFetchOptions, shell: shell)!.cacheRoot()
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDir))
        try? FileManager.default.removeItem(atPath: cacheDir)
    }

    func testGitBranchDownloading() {
        let shell = SystemShellContext()
        let gitFetchOptions = FetchOptions(
            podName: "Kingfisher",
            url: "git@github.com:onevcat/Kingfisher.git",
            trace: false,
            subDir: nil,
            revision: "branch:master;")
        RepoActions.fetch(shell: shell, fetchOptions: gitFetchOptions)

        let cacheDir = GitDownloader(options: gitFetchOptions, shell: shell)!.cacheRoot()
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDir))
        try? FileManager.default.removeItem(atPath: cacheDir)
    }

    func testGitTagDownloading() {
        let shell = SystemShellContext()
        let gitFetchOptions = FetchOptions(
            podName: "Kingfisher",
            url: "git@github.com:onevcat/Kingfisher.git",
            trace: false,
            subDir: nil,
            revision: "tag:7.2.2;")
        RepoActions.fetch(shell: shell, fetchOptions: gitFetchOptions)

        let cacheDir = GitDownloader(options: gitFetchOptions, shell: shell)!.cacheRoot()
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDir))
        try? FileManager.default.removeItem(atPath: cacheDir)
    }

    func testGitBranchAndCommitDownloading() {
        let shell = SystemShellContext()
        let gitFetchOptions = FetchOptions(
            podName: "Kingfisher",
            url: "git@github.com:onevcat/Kingfisher.git",
            trace: false,
            subDir: nil,
            revision: "commit:59eb199;branch:master")
        RepoActions.fetch(shell: shell, fetchOptions: gitFetchOptions)

        let cacheDir = GitDownloader(options: gitFetchOptions, shell: shell)!.cacheRoot()
        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheDir))
        try? FileManager.default.removeItem(atPath: cacheDir)
    }

    func testGitTagAndBranchDownloading() {
        // TODO: FatalError should be encountered here, there is no good way to verify this case

        // let shell = SystemShellContext()
        // let gitFetchOptions = FetchOptions(
        //    podName: "Kingfisher",
        //    url: "git@github.com:onevcat/Kingfisher.git",
        //    trace: false,
        //    subDir: nil,
        //    revision: "branch:master;tag:7.2.2;")
        // RepoActions.fetch(shell: shell, fetchOptions: gitFetchOptions)
    }
    
    func testZipExtraction() {
        let hasDir =  MakeShellInvocation("/bin/[", arguments: ["-e",
                cacheRoot(forPod: testPodName, url: "http://pinner.com/foo.zip"),
                "]"], exitCode: 1)

        
        let extract = MakeShellInvocation("/bin/sh",
                                          arguments: ["-c", HttpDownloader.unzipTransaction(
                                            rootDir: escape(extractDir),
                                            fileName: escape(downloadPath)
                                            )],
                                          exitCode: 0)
        let shell = LogicalShellContext(commandInvocations: [
            hasDir,
            extract
            ])

        RepoActions.fetch(shell: shell, fetchOptions: fetchOpts)
        XCTAssertTrue(shell.executed(encodedCommand:
                LogicalShellContext.encodeDownload(url: URL(string: fetchOpts.url)!, toFile: downloadPath)
        ))
        XCTAssertTrue(shell.executed(encodedCommand: extract.0))
    }

    func testCachedDownload() {
        let hasDir =  MakeShellInvocation("/bin/[", arguments: ["-e", cacheRoot(forPod: testPodName, url: "http://pinner.com/foo.zip"), "]"], value: 0)
        let shell = LogicalShellContext(commandInvocations: [
            hasDir,
            ])
        
        RepoActions.fetch(shell: shell, fetchOptions: fetchOpts)
        XCTAssertFalse(shell.executed(encodedCommand:
                LogicalShellContext.encodeDownload(url: URL(string: fetchOpts.url)!, toFile: downloadPath)
        ))
    }
}
