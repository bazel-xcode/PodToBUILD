//
//  RuleUtils.swift
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
        includingFileTypes: Set<String>, usePrefix: Bool = true) ->
AttrSet<[String]> {
    let sourcePrefix = usePrefix ? getSourcePatternPrefix() : ""
    return patternSet.map {
        (patterns: [String]) -> [String] in
        let result = patterns.flatMap { (p: String) -> [String] in
            pattern(fromPattern: sourcePrefix + p, includingFileTypes:
                    includingFileTypes)
        }
        return result
    }
}

public func extractFiles(fromPattern patternSet: [String],
        includingFileTypes: Set<String>, usePrefix: Bool = true) -> [String] {
    let sourcePrefix = usePrefix ? getSourcePatternPrefix() : ""
    return patternSet.flatMap { (p: String) -> [String] in
            pattern(fromPattern: sourcePrefix + p, includingFileTypes:
                    includingFileTypes)
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

/// We need to hardcode a copt to the $(GENDIR) for simplicity.
/// Expansion of $(location //target) is not supported in known Xcode generators
public func getGenfileOutputBaseDir() -> String {
    let options = GetBuildOptions()
    /// FIXME: for XcodeToBUILD we need to add expansion
    let basePath = options.vendorize ? "Vendor" : "external"
    //let basePath = options.vendorize ? "Pods" : "external"
    let podName = options.podName
    let parts = options.path.split(separator: "/")
    if options.path ==  "." || parts.count < 2 {
        return "\(basePath)/\(podName)"
    }

    return String(parts[0..<2].joined(separator: "/"))
}

public func getNamePrefix() -> String {
    let options = GetBuildOptions()
    if options.path.split(separator: "/").count > 2 {
        return options.podName + "_"
    }
    return ""
}

public func getSourcePatternPrefix() -> String {
    let options = GetBuildOptions()
    let parts = options.path.split(separator: "/")
    if options.path ==  "." || parts.count < 2 {
        return ""
    }
    let sourcePrefix = String(parts[2..<parts.count].joined(separator: "/"))
    if sourcePrefix != "" {
        return sourcePrefix + "/"
    }
    return ""
}

/// Compute the name of a lib
public func computeLibName(parentSpecs: [PodSpec], spec: PodSpec, podName: String, isSplitDep: Bool = false, sourceType: BazelSourceLibType) -> String {
    let splitSuffix = isSplitDep ? sourceType.getLibNameSuffix() : ""
    let baseName = parentSpecs.isEmpty
            ? podName
            : bazelLabel(
                fromString: (parentSpecs + [spec])[1...]
                    .map { $0.moduleName ?? $0.name }
                    .joined(separator: "_")
            )
    return getNamePrefix() + baseName + splitSuffix
}

/// Get a dependency name from a name in accordance with
/// CocoaPods dependency naming ( slashes )
/// Versions are ignored!
/// When a given dependency is locally spec'ed, it should
/// Match the PodName i.e. PINCache/Core
public func getDependencyName(fromPodDepName podDepName: String, podName: String) -> String  {
    let results = podDepName.components(separatedBy: "/")
    if results.count > 1 && results[0] == podName {
        // This is a local subspec reference
        let join = results[1 ... results.count - 1].joined(separator: "/")
        return ":\(getNamePrefix() + bazelLabel(fromString: join))"
    } else {
        if results.count > 1 {
            let join = results[1 ... results.count - 1].joined(separator: "/")
            return getRulePrefix(name: results[0],
                    preceedsTarget: true) +
                "\(bazelLabel(fromString: join))"
        } else {
            // This is a reference to another pod library
            return getRulePrefix(name:
                    bazelLabel(fromString: results[0]),
                    preceedsTarget: true)  +
                "\(bazelLabel(fromString: results[0]))"
        }
    }
}

/// Convert a string to a Bazel label conventional string
public func bazelLabel(fromString string: String) -> String {
	return string.replacingOccurrences(of: "/", with: "_")
				 .replacingOccurrences(of: "+", with: "_")
}


