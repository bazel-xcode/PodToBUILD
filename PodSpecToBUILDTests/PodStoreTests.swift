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
        return escape(PodStoreCacheDir + "dls")
    }
    
	var download: String {
        return downloads + "/" + testPodName + "-" + "foo.zip"
    }   
        
    var curl: ShellInvocation {
        return MakeShellInvocation("/usr/bin/curl", arguments: ["-Lk",
                    "http://pinner.com/foo.zip", "-o", download], value: true)
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
            hasDir,
            curl
            ])
        RepoActions.fetch(shell: shell, fetchOptions: fetchOpts)
        XCTAssertTrue(shell.executed(encodedCommand: curl.0))
    }
    
    func testZipExtraction() {
        let curl =  MakeShellInvocation("/usr/bin/curl", arguments: ["-Lk",
                "http://pinner.com/foo.zip", "-o", download], value: true)
        let hasDir =  MakeShellInvocation("/bin/[", arguments: ["-e",
                cacheRoot(forPod: testPodName, url: "http://pinner.com/foo.zip"),
                "]"], exitCode: 1)

        let extractDir = escape("/tmp/bazel_pod_download-" + testPodName)
        let extract = MakeShellInvocation("/bin/sh", 
                arguments: ["-c", RepoActions.unzipTransaction(
                    rootDir: escape(extractDir),
                    fileName: escape(download)
                    )
                ],
                exitCode: 0)
        let shell = LogicalShellContext(commandInvocations: [
            hasDir,
            curl,
            extract
            ])

        RepoActions.fetch(shell: shell, fetchOptions: fetchOpts)
        XCTAssertTrue(shell.executed(encodedCommand: curl.0))
        XCTAssertTrue(shell.executed(encodedCommand: extract.0))
    }

    func testCachedDownload() {
        let curl =  MakeShellInvocation("/usr/bin/curl", arguments: ["-LOk", "http://pinner.com/foo.zip"], value: true)
        let hasDir =  MakeShellInvocation("/bin/[", arguments: ["-e", cacheRoot(forPod: testPodName, url: "http://pinner.com/foo.zip"), "]"], value: 0)
        let shell = LogicalShellContext(commandInvocations: [
            hasDir,
            curl,
            ])
        
        RepoActions.fetch(shell: shell, fetchOptions: fetchOpts)
        XCTAssertFalse(shell.executed(encodedCommand: curl.0))
    }
}
