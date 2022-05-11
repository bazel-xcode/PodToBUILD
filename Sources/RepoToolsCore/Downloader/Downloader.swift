//
//  Downloader.swift
//  
//
//  Created by Crazy凡 on 2022/5/10.
//

import Foundation
import PodToBUILD
import CloudKit

let Downloaders: [Downloader.Type] = [
    HttpDownloader.self,
    GitDownloader.self
]

protocol Downloader {
    init?(options: FetchOptions, shell: ShellContext)

    /// Cache dir for options
    /// - Parameter options: options from preprocess
    /// - Returns: cache dir
    func cacheRoot() -> String

    /// Download and extract if necessary.
    /// - Parameters:
    ///   - shell: shell context
    ///   - options: options from preprocess
    func download(shell: ShellContext) -> String
}

extension Downloader {
    init?(options: FetchOptions, shell: ShellContext) {
        fatalError("Should never be called")
    }

    /// Cache dir for options
    /// - Parameter options: options from preprocess
    /// - Returns: cache dir
    func cacheRoot() -> String {
        fatalError("Should never be called")
    }

    /// Download and extract if necessary.
    /// - Parameters:
    ///   - shell: shell context
    ///   - options: options from preprocess
    func download(shell: ShellContext) -> String {
        fatalError("Should never be called")
    }
}
