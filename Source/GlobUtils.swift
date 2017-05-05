//
//  GlobUtils.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/18/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation
import Darwin

// ============================================
//
//  Created by Eric Firestone on 3/22/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
//  Released under the Apache v2 License.
//
//  Adapted from https://gist.github.com/efirestone/ce01ae109e08772647eb061b3bb387c3
//  Adapted again from https://github.com/Bouke/Glob/blob/master/Sources/Glob.swift

public let GlobBehaviorBashV3 = Glob.Behavior(
    supportsGlobstar: false,
    includesFilesFromRootOfGlobstar: false,
    includesDirectoriesInResults: true,
    includesFilesInResultsIfTrailingSlash: false
)
public let GlobBehaviorBashV4 = Glob.Behavior(
    supportsGlobstar: true, // Matches Bash v4 with "shopt -s globstar" option
    includesFilesFromRootOfGlobstar: true,
    includesDirectoriesInResults: true,
    includesFilesInResultsIfTrailingSlash: false
)
public let GlobBehaviorGradle = Glob.Behavior(
    supportsGlobstar: true,
    includesFilesFromRootOfGlobstar: true,
    includesDirectoriesInResults: false,
    includesFilesInResultsIfTrailingSlash: true
)

/**
 Finds files on the file system using pattern matching.
 */
public class Glob: Collection {

    /**
     * Different glob implementations have different behaviors, so the behavior of this
     * implementation is customizable.
     */
    public struct Behavior {
        // If true then a globstar ("**") causes matching to be done recursively in subdirectories.
        // If false then "**" is treated the same as "*"
        let supportsGlobstar: Bool

        // If true the results from the directory where the globstar is declared will be included as well.
        // For example, with the pattern "dir/**/*.ext" the fie "dir/file.ext" would be included if this
        // property is true, and would be omitted if it's false.
        let includesFilesFromRootOfGlobstar: Bool

        // If false then the results will not include directory entries. This does not affect recursion depth.
        let includesDirectoriesInResults: Bool

        // If false and the last characters of the pattern are "**/" then only directories are returned in the results.
        let includesFilesInResultsIfTrailingSlash: Bool
    }

    static var defaultBehavior = GlobBehaviorBashV4

    private var isDirectoryCache = [String: Bool]()

    public let behavior: Behavior
    var paths = [String]()
    public var startIndex: Int { return paths.startIndex }
    public var endIndex: Int { return paths.endIndex }

    public init(pattern: String, behavior: Behavior = Glob.defaultBehavior) {

        self.behavior = behavior

        var adjustedPattern = pattern
        let hasTrailingGlobstarSlash = pattern.hasSuffix("**/")
        var includeFiles = !hasTrailingGlobstarSlash

        if behavior.includesFilesInResultsIfTrailingSlash {
            includeFiles = true
            if hasTrailingGlobstarSlash {
                // Grab the files too.
                adjustedPattern += "*"
            }
        }

        let patterns = behavior.supportsGlobstar ? expandGlobstar(pattern: adjustedPattern) : [adjustedPattern]

        for pattern in patterns {
            var gt = glob_t()
            if executeGlob(pattern: pattern, gt: &gt) {
                populateFiles(gt: gt, includeFiles: includeFiles)
            }

            globfree(&gt)
        }

        paths = Array(Set(paths)).sorted { lhs, rhs in
            lhs.compare(rhs) != ComparisonResult.orderedDescending
        }

        clearCaches()
    }

    // MARK: Private

    private var globalFlags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK

    private func executeGlob(pattern: UnsafePointer<CChar>, gt: UnsafeMutablePointer<glob_t>) -> Bool {
        return 0 == glob(pattern, globalFlags, nil, gt)
    }

    private func expandGlobstar(pattern: String) -> [String] {
        guard pattern.contains("**") else {
            return [pattern]
        }

        var results = [String]()
        var parts = pattern.components(separatedBy: "**")
        let firstPart = parts.removeFirst()
        var lastPart = parts.joined(separator: "**")

        let fileManager = FileManager.default

        var directories: [String]

        do {
            directories = try fileManager.subpathsOfDirectory(atPath: firstPart).flatMap { subpath in
                let fullPath = NSString(string: firstPart).appendingPathComponent(subpath)
                var isDirectory = ObjCBool(false)
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                    return fullPath
                } else {
                    return nil
                }
            }
        } catch {
            directories = []
            print("Error parsing file system item: \(error)")
        }

        if behavior.includesFilesFromRootOfGlobstar {
            // Check the base directory for the glob star as well.
            directories.insert(firstPart, at: 0)

            // Include the globstar root directory ("dir/") in a pattern like "dir/**" or "dir/**/"
            if lastPart.isEmpty {
                results.append(firstPart)
            }
        }

        if lastPart.isEmpty {
            lastPart = "*"
        }
        for directory in directories {
            let partiallyResolvedPattern = NSString(string: directory).appendingPathComponent(lastPart)
            results.append(contentsOf: expandGlobstar(pattern: partiallyResolvedPattern))
        }

        return results
    }

    private func isDirectory(path: String) -> Bool {
        var isDirectory = isDirectoryCache[path]
        if let isDirectory = isDirectory {
            return isDirectory
        }

        var isDirectoryBool = ObjCBool(false)
        isDirectory = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectoryBool) && isDirectoryBool.boolValue
        isDirectoryCache[path] = isDirectory!

        return isDirectory!
    }

    private func clearCaches() {
        isDirectoryCache.removeAll()
    }

    private func populateFiles(gt: glob_t, includeFiles: Bool) {
        let includeDirectories = behavior.includesDirectoriesInResults

        for i in 0 ..< Int(gt.gl_matchc) {
            if let path = String(validatingUTF8: gt.gl_pathv[i]!) {
                if !includeFiles || !includeDirectories {
                    let isDirectory = self.isDirectory(path: path)
                    if (!includeFiles && !isDirectory) || (!includeDirectories && isDirectory) {
                        continue
                    }
                }

                paths.append(path)
            }
        }
    }

    // MARK: Subscript Support

    public subscript(i: Int) -> String {
        return paths[i]
    }

    // MARK: IndexableBase

    public func index(after i: Glob.Index) -> Glob.Index {
        return i + 1
    }
}

// ============================================

// Glob
// Return True if the pattern contains the needle
func glob(pattern: String, contains needle: String) -> Bool {
    guard let regex = try? NSRegularExpression(withGlobPattern: pattern) else {
        return false
    }
    let match = regex.matches(in: needle)
    return match.count != 0
}

// Pattern ( Bazel Specific )
// Return a subset of the pattern for a given file type
// If the pattern does not contain file type, then return nil
// Note that we take the first match.
//
// Background:
// In PodSpec, there are heterogeneous file globs, for example Some/*.{h, m}
// or Some/**/*
//
// In Bazel, we need to specify specific subsets of the files in various parts
// of the BUILD file.
//
// For example, we can only use .h files in headers and .m files in srcs
//
// Additionally, we need to create multiple insertions for each file type since
// Bazel does not support character group globs
func pattern(fromPattern pattern: String, includingFileType fileType: String) -> String? {
    var result = ""
    let components = pattern.components(separatedBy: "/")
    var matches = [String]()
    var patternComponent = ""
    var fileExtensions = Set<String>()
    for (componentIdx, component) in components.enumerated() {
        if componentIdx != components.count - 1 {
            result += "\(component)/"
            continue
        }

        let extensionComponents = component.components(separatedBy: ".")
        if extensionComponents.count < 2 {
            continue
        }

        var fileExtension = ""
        for (idx, e) in extensionComponents.enumerated() {
            fileExtension = e
            if extensionComponents.count > 1 && idx == extensionComponents.count - 1 {
                break
            }
            result += e
            result += "."
        }
        fileExtensions.insert(fileExtension)

        // Pattern Substitution
        var inPattern = false
        func exitPattern() {
            if fileType == patternComponent {
                result += patternComponent
                matches.append(patternComponent)
            }
            patternComponent = ""
            inPattern = false
        }
        func enterPattern() {
            inPattern = true
        }

        for (_, strIdx) in fileExtension.characters.indices.enumerated() {
            let c = fileExtension[strIdx]
            if c == "[" {
                enterPattern()
                continue
            } else if c == "{" {
                enterPattern()
                continue
            } else if c == "}" {
                exitPattern()
                if matches.count > 0 {
                    break
                }
                continue
            } else if c == "]" {
                exitPattern()
                if matches.count > 0 {
                    break
                }
                continue
            } else if c == "," || c == "|" {
                if fileType == patternComponent {
                    result += patternComponent
                    matches.append(patternComponent)
                }
                // Still in the pattern - terminate the match
                patternComponent = ""
                continue
            }
            if inPattern {
                patternComponent += String(c)
                continue
            }
            result += String(c)
        }
    }
    if fileType == patternComponent {
        matches.append(patternComponent)
    }

    if matches.count == 0 {
        // Don't mix up patterns that have non matching file extensions
        // within them
        if fileExtensions.isEmpty,
            let last = pattern.unicodeScalars.last,
            CharacterSet.alphanumerics.contains(last) {
            // If there is no matches, and the last character is alphanumeric,
            // then we'll assume they meant to write a pattern that was a
            // recursive glob.
            return "\(pattern)/**/*.\(fileType)"
        }
        return nil
    }
    return result
}

// Glob with the semantics of pod `source_file` globs.
// @note the original PodSpec globs are based on the ruby glob semantics
func podGlob(pattern: String) -> [String] {
    return Glob(pattern: pattern, behavior: GlobBehaviorBashV4).paths
}

// MARK: - NSRegularExpression

extension NSRegularExpression {

    // Convert a glob to a regex
    class func pattern(withGlobPattern pattern: String) -> String {
        var regexStr = ""
        for idx in pattern.characters.indices {
            let c = pattern[idx]
            if c == "*" {
                regexStr.append(".*")
            } else if c == "?" {
                regexStr.append(".")
            } else if c == "[" {
                regexStr.append("[")
            } else if c == "]" {
                regexStr.append("[")
            } else if c == "{" {
                regexStr.append("[")
            } else if c == "}" {
                regexStr.append("]")
            } else {
                regexStr.append(c)
            }
        }
        return regexStr
    }

    convenience init(withGlobPattern pattern: String) throws {
        let globPattern = NSRegularExpression.pattern(withGlobPattern: pattern)
        try self.init(pattern: globPattern)
    }

    func matches(in text: String) -> [String] {
        let nsString = text as NSString
        let results = matches(in: text, range: NSRange(location: 0, length: nsString.length))
        return results.map { nsString.substring(with: $0.range) }
    }
}

