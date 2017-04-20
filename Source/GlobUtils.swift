//
//  GlobUtils.swift
//  PodSpecToBUILD
//
//  Created by jerry on 4/18/17.
//  Copyright © 2017 jerry. All rights reserved.
//

import Foundation
import Darwin

// Glob
// Wrapper for posix glob
public func glob(pattern: String) -> [String] {
    let globFlags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
    guard let s = pattern.cString(using: .utf8), let cstr = strdup(s) else {
        return [String]()
    }
    var paths = [String]()
    var globResult = glob_t()
    if glob(cstr, globFlags, nil, &globResult) == 0 && globResult.gl_matchc != 0 {
        for i in 1 ... Int(globResult.gl_matchc) {
            if let v = globResult.gl_pathv[i] {
                paths.append(String(cString: v))
            }
        }
    }
    return paths
}

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
        return nil
    }
    return result
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
