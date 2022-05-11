//
//  Http.swift
//
//
//  Created by Crazy凡 on 2022/5/10.
//

import Foundation
import PodToBUILD

private struct HttpOptions {
    let podName: String
    let url: String

    init?(_ options: FetchOptions) {
        guard HttpOptions.isHttpURL(options.url) else { return nil }

        self.podName = options.podName
        self.url = options.url
    }

    private static func isHttpURL(_ url: String) -> Bool {
        return url.hasPrefix("http://") || url.hasPrefix("https://")
    }
}

struct HttpDownloader: Downloader {
    private var options: HttpOptions

    init?(options: FetchOptions, shell: ShellContext) {
        guard let _options = HttpOptions(options) else {
            return nil
        }

        self.options = _options
    }

    func cacheRoot() -> String {
        PodStoreCacheDir + options.podName + "-" + options.url.sha256() + "/"
    }

    func download(shell: ShellContext) -> String {
        let podName = options.podName
        let urlString = options.url

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
                    HttpDownloader.unzipTransaction(
                        rootDir: extractDir,
                        fileName: escape(download)
                    )
                ])
            } else if
                lowercasedFileName.hasSuffix("tar")
                    || lowercasedFileName.hasSuffix("tar.gz")
                    || lowercasedFileName.hasSuffix("tgz")
                    || lowercasedFileName.hasSuffix("txz") // txz is a txz extension
                    || lowercasedFileName.hasSuffix("tar.xz") // tar.xz is a txz extension
            {
                return shell.command(CommandBinary.sh, arguments: [
                    "-c",
                    HttpDownloader.untarTransaction(
                        rootDir: extractDir,
                        fileName: escape(download)
                    )
                ])
            }
            fatalError("Cannot extract files other than .zip, .tar, .tar.gz, tar.xz, txz or .tgz. Got \(lowercasedFileName)")
        }

        RepoActions.assertCommandOutput(extract(), message: "Extraction of \(podName) failed")

        return extractDir + "/OUT" // extract method will append path component "OUT"
    }
}

extension HttpDownloader {
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
