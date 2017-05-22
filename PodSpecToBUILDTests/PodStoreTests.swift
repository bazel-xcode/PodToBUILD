//
//  PodStoreTests.swift
//  PodStoreTests
//
//  Created by jerry on 5/9/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import XCTest

let testPodName = "Foo"

let fetchOpts = FetchOptions(podName: testPodName,
                    url: "http://pinner.com/foo.zip",
                    trace: false,
                    subDir: nil)

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
    
    func testZipExtraction() {
        let hasDir =  MakeShellInvocation("/bin/[", arguments: ["-e",
                cacheRoot(forPod: testPodName, url: "http://pinner.com/foo.zip"),
                "]"], exitCode: 1)

        
        let extract = MakeShellInvocation("/bin/sh",
                                          arguments: ["-c", RepoActions.unzipTransaction(
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
