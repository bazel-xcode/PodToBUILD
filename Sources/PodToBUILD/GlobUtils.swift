//
//  GlobUtils.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 4/18/17.
//  Copyright © 2017 Pinterest Inc. All rights reserved.
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

    public static var defaultBehavior = GlobBehaviorBashV4

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
        // If using an empty filepath then no need to look for it
        if !firstPart.isEmpty {
            do {
                directories = try fileManager.subpathsOfDirectory(atPath: firstPart).compactMap { subpath in
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
        } else {
            directories = []
            print("Error parsing file system item: EMPTY")
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

// Grammar for RubyGlob pieces
enum RubyGlobChunk {
    case Wild // *
    case DirWild // **
    case DotStarWild // .*
    case CharWild // just one character but anything
    case Either(Set<String>) // matches any string here
    case Str(String)
}
extension RubyGlobChunk: Equatable {
    static func ==(lhs: RubyGlobChunk, rhs: RubyGlobChunk) -> Bool {
        switch (lhs, rhs) {
        case (.Wild, .Wild), (.DirWild, .DirWild), (.CharWild, .CharWild): return true
        case let (.Either(s1), .Either(s2)):
            return s1 == s2
        case let (.Str(s1), .Str(s2)):
            return s1 == s2
        default:
            return false
        }
    }
}

// Bazel supports only a subset of Ruby's globs
enum BazelGlobChunk {
    case Wild
    case DirWild
    case DotStarWild
    case Str(String)
}
extension BazelGlobChunk: Equatable {
    static func ==(lhs: BazelGlobChunk, rhs: BazelGlobChunk) -> Bool {
        switch (lhs, rhs) {
        case (.Wild, .Wild), (.DirWild, .DirWild): return true
        case let (.Str(s1), .Str(s2)): return s1 == s2
        default: return false
        }
    }
    
    func hasSuffix(_ suffix: String) -> Bool {
        switch self {
        case .Wild, .DotStarWild, .DirWild:
            return false
        case let .Str(s):
            return s.hasSuffix(suffix)
        }
    }
}


// * is Wild
let star = Parsers.just("*")
let parseWild: Parser<RubyGlobChunk> = star.map{ _ in RubyGlobChunk.Wild }
// ** is DirWild
let starstar = Parsers.prefix(["*", "*"])
let parseDirWild: Parser<RubyGlobChunk> = starstar.map{ _ in RubyGlobChunk.DirWild }

// .*
let dotStar = Parsers.prefix([".", "*"])
let parseDotStarWild: Parser<RubyGlobChunk> = dotStar.map{ _ in RubyGlobChunk.DotStarWild }

// ? is CharWild
let questionmark = Parsers.just("?")
let parseCharWild: Parser<RubyGlobChunk> = questionmark.map{ _ in RubyGlobChunk.CharWild }

// {h, y, z} yields Either(["h", "y", "z"])
let comma = Parsers.just(",")
// one piece of the {} curly set
let curlyChunk = Parsers.anyChar.butNot("}") // need to exclude "}" to counter greediness
    .manyUntil(terminator: comma.forget)
// matches 1, 2, 3
let curlyChunks = curlyChunk
    .rep(separatedBy: (comma.andThen{  Parsers.whitespace.many() }).forget)
// now we wrap with { }
let parseCurlySet: Parser<RubyGlobChunk> =
    curlyChunks
        .wrapped(startingWith: "{", endingWith: "}")
        .map{ css in RubyGlobChunk.Either(Set(css.map{ String($0) })) }

// [hm] yields Either(["h", "m"])
let parseCharacterSet: Parser<RubyGlobChunk> =
    Parsers.anyChar.butNot("]") // a single character (counter greediness by excluding ])
        .manyUntil(terminator: Parsers.just("]").forget) // repeated
        .wrapped(startingWith: "[", endingWith: "]") // wrapped up
        .map{ cs in RubyGlobChunk.Either(Set(cs.map{ String($0) }))}

// Either can be {h,m} or [hm]
let parseEither = parseCurlySet.orElse(parseCharacterSet)

// Special glob chunks are everything except plain strings
// we need to check these first and fallthrough.
// The order matters: We must check DirWild before Wild or
// we will parse incorrectly.
let parseSpecial =
    Parser.first([
        parseDirWild, // **
        parseDotStarWild, // **
        parseWild, // *
        parseCharWild, // ?
        parseEither // [hm]
    ])

// A non-empty group of repeated characters (until hitting a special sequence of
// tokens) forms a string in the regex.
// NOTE: This is strictly MORE powerful than Ruby since we will parse "abc["
//       but Cocoapods will have valid regexes so this isn't be a problem.
let parseStr: Parser<RubyGlobChunk> =
    Parsers.anyChar.manyUntil(terminator: parseSpecial.forget, atLeast: 1)
        .map{ cs in RubyGlobChunk.Str(String(cs)) }

// One chunk of ruby is either a special chunk or a string
let parseOneRubyChunk: Parser<RubyGlobChunk> =
    Parser.first([
        parseSpecial,
        parseStr
    ])

// A glob is a repeated sequence of ruby chunks
let parseGlob: Parser<[RubyGlobChunk]> = parseOneRubyChunk.many()

extension Sequence where Iterator.Element == RubyGlobChunk {
    // This takes every non-deterministic path and replaces with all cases
    // outer list is different regexes
    // inner list is one regex
    func toBazelChunks() -> [[BazelGlobChunk]] {
        // TODO: Use linked list
        // The runtime complexity of this transformation is abhorrent
        return self.reduce([[]]) { (acc, x) in
            let foo: RubyGlobChunk = x
            switch foo {
            case .Wild:
                return acc.map{ cs in cs + [BazelGlobChunk.Wild] }
            case .DotStarWild:
                return acc.map{ cs in cs + [BazelGlobChunk.DotStarWild] }
            case .DirWild:
                return acc.map{ cs in cs + [BazelGlobChunk.DirWild] }
            case .CharWild:
                fatalError("Unsupported chunk (CharWild)")
            case let .Either(strs):
                return acc.flatMap { cs in
                    // cs is one different regex
                    // for every char we want to make a new regex
                    strs.map{ str in
                        cs + [BazelGlobChunk.Str(str)]
                    }
                }
            case let .Str(str):
                return acc.map { cs in cs + [BazelGlobChunk.Str(str)]}
            }
        }
    }
}

extension Sequence where Iterator.Element == BazelGlobChunk {
    // [.Str(a), .Str(b)] means the same as .Str(a + b)
    // We can simplify our representation by performing that transformation on our IR
    // This means the .Str constructor is a string concat homomorphism
    var simplify: [BazelGlobChunk] {
        return self.reduce([BazelGlobChunk]()) { (acc, x) in
            switch (acc.last, x) {
            case let (.some(.Str(s1)), .Str(s2)):
                var accCopy = acc
                accCopy[acc.count-1] = .Str(s1 + s2)
                return accCopy
            default:
                return acc + [x]
            }
        }
    }
    
    var bazelString: String {
        return self.reduce("") { (acc, x) in
            switch x {
            case .Wild:
                return acc + "*"
            case .DotStarWild:
                // represent DotStarWild as a file extension.
                return acc
            case .DirWild:
                return acc + "**"
            case let .Str(str):
                return acc + str
            }
        }
    }
}

// Pattern ( Bazel Specific )
// Return all subsets of the pattern for a given file type
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
public func pattern(fromPattern pattern: String, includingFileTypes fileTypes: Set<String>) -> [String] {
    // if we have a proper ruby pattern,
    if let arr = parseGlob.parseFully(Array(pattern)) {
        // Remove empty empty chunks
        let filtered: [[BazelGlobChunk]] = arr.toBazelChunks()
            .map{ $0.simplify }
            .filter{ (bazelChunks: [BazelGlobChunk]) -> Bool in
                bazelChunks.count != 0 && bazelChunks[0] != BazelGlobChunk.Str("")
        }

        // Allow all file types
        if fileTypes.count == 0 {
             let strs: [String] = filtered
                  .map{ (glob: [BazelGlobChunk]) -> String in glob.bazelString }
             return Array(Set(strs))
        }
        // In Bazel, to keep things simple, we want all patterns to end in an extension
        // Unfortunately, Cocoapods patterns could end in anything, so we need to fix them all
        let suffixFixed: [[BazelGlobChunk]] = filtered
            .flatMap{ (bazelGlobChunks: [BazelGlobChunk]) -> [[BazelGlobChunk]] in
                let lastChunk = bazelGlobChunks.last! // count != 0 already filtered out
                switch lastChunk {
                // ending in * needs to map to *.m (except .*)
                case .Wild, .DotStarWild:
                    let lastTwo = Array(bazelGlobChunks.suffix(2))
                    // if we end in .*
                    if (lastTwo.count == 2 && lastTwo[0].hasSuffix(".")) {
                        return fileTypes.map{
                            // strip the last * and replace with the extension
                            bazelGlobChunks.prefix(upTo: bazelGlobChunks.count-1) + [BazelGlobChunk.Str($0)]
                        }
                    } else {
                        // otherwise we can just append the extension
                        return fileTypes.map{ bazelGlobChunks + [BazelGlobChunk.Str($0)] }
                    }
                // ending in ** needs to map to **/*.m
                case .DirWild:
                     return fileTypes.map{ bazelGlobChunks + [.Str("/"), .Wild, .Str($0)] }
                // ending in a string if that string doesn't have an extension
                // needs the full /**/*.m
                case let .Str(s):
                    let allButLast = bazelGlobChunks.count >= 2 ? bazelGlobChunks.prefix(upTo: bazelGlobChunks.count-1) : []
                    // assume that alphanumeric suffix is an extension
                    let regex = try! NSRegularExpression(pattern: "\\.[^/]*$", options: [])
                    return fileTypes.map{ (fileType: String) -> [BazelGlobChunk] in
                        return regex.matches(in: s).count > 0 ?
                            allButLast + [lastChunk] :
                            allButLast + [lastChunk, .Str("/"), .DirWild, .Str("/"), .Wild, .Str(fileType)]
                    }
                }
            }

        // compile the bazel chunks
        let strs: [String] = suffixFixed
            .map{ (glob: [BazelGlobChunk]) -> String in glob.bazelString }

        return Array(Set(strs))
            // Only include patterns that contain the suffixes we care about
            .filter{ (bazelRegex: String) -> Bool in
                // if at least one of the filetypes we're checking matches then we're good
                (fileTypes.filter { fileType in
                    bazelRegex.hasSuffix(fileType)
                }).count > 0
            }
    } else {
        return []
    }
}

// Glob with the semantics of pod `source_file` globs.
// @note the original PodSpec globs are based on the ruby glob semantics
public func podGlob(pattern: String) -> [String] {
    return Glob(pattern: pattern, behavior: GlobBehaviorBashV4).paths
}

// MARK: - NSRegularExpression

extension NSRegularExpression {

    // Convert a glob to a regex
    class func pattern(withGlobPattern pattern: String) -> String {
        var regexStr = ""

        for idx in pattern.indices {
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

