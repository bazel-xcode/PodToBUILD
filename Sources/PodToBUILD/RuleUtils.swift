//
//  ObjcLibrary.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 9/20/2018.
//  Copyright © 2018 Pinterest Inc. All rights reserved.
//

public enum BazelSourceLibType {
    case objc
    case swift
    case cpp

    func getLibNameSuffix() -> String {
        switch self {
        case .objc:
            return "_objc"
        case .cpp:
            return "_cxx"
        case .swift:
            return "_swift"
        }
    }
}

/// Extract files from a source file pattern.
public func extractFiles(fromPattern patternSet: AttrSet<[String]>,
        includingFileTypes: Set<String>) ->
AttrSet<[String]> {
    return patternSet.map {
        (patterns: [String]) -> [String] in
        let result = patterns.flatMap { (p: String) -> [String] in
            pattern(fromPattern: p, includingFileTypes:
                    includingFileTypes)
        }
        return result
    }
}

let ObjcLikeFileTypes = Set([".m", ".c", ".s", ".S"])
let CppLikeFileTypes  = Set([".mm", ".cpp", ".cxx", ".cc"])
let SwiftLikeFileTypes  = Set([".swift"])
let HeaderFileTypes = Set([".h", ".hpp", ".hxx"])


public func makeAlias(name: String, actual: String) -> SkylarkNode {
    return SkylarkNode.functionCall(
        name: "alias",
        arguments: [
            .named(name: "name", value: .string(name)),
            .named(name: "actual", value: .string(actual)),
            .named(name: "visibility", value: .list(["//visibility:public"]))
        ])
}

public func getRulePrefix(name: String, preceedsTarget: Bool = false) -> String {
    let options = GetBuildOptions()
    return options.vendorize ?
        "//Vendor/\(name)" + (preceedsTarget ? ":" : "/") :
        "@\(name)" + (preceedsTarget ? "//:" : "//")
}

public func getPodBaseDir() -> String {
    let options = GetBuildOptions()
    return options.vendorize ? "Vendor" : "external"
}


