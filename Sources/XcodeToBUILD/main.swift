import Foundation
import PathKit
import PodToBUILD
import XcodeProj

struct XCSettings {
    let basePath: String?
    let settings: [String: Any]

    public static func merge(settings: [XCSettings]) -> [String: Any] {
        return merge(settings: settings.reduce(into: [[String: Any]]()) {
            accum, next in
            accum.append(next.settings)
            accum.append(next.loadSettings())
        })
    }

    /// Given a string expand the xcconfig values for that string
    public static func expand(_ strVal: String, settings: [String: Any]) -> String? {
        // TODO: consider implementing an XCConfig evaluator.
        // for now, we handle _cocoapods_ specific aspects of the spec
        // At this point, assume inherited has been subbed out
        if strVal == "$(inherited)" {
            return nil
        }
        let podsTargetSRCRoot = settings["PODS_TARGET_SRCROOT"] as? String ?? ""
        return strVal
            .replacingOccurrences(of: "$(PODS_TARGET_SRCROOT)", with: podsTargetSRCRoot)
            .replacingOccurrences(of: "${PODS_ROOT}", with: "Pods")
            .replacingOccurrences(of: "$(PODS_ROOT)", with: "Pods")
            .replacingOccurrences(of: "\"", with: "")
    }

    private func loadSettings() -> [String: Any] {
        if let basePath = basePath {
            // The XcodeProj code assume that we're giving it a valid rel path
            // to the CWD or absolute path. It doesn't need to fail on an
            // invalid xccofig but makes it a bit eaiser
            guard let config = try? XCConfig(path: Path(basePath)) else {
                fatalError("invalid xcconfig at:" + basePath)
            }
            return config.buildSettings
        }
        return [:]
    }

    private static func merge(settings: [[String: Any]]) -> [String: Any] {
        // FIXME: we don't ever look at the `settings`..
        return settings.reduce(into: [String: Any]()) {
            accum, next in
            next.forEach {
                key, value in
                if let existing = accum[key] as? String,
                    let strVal = value as? String {
                    if strVal.contains("$(inherited)") {
                        accum[key] = strVal.replacingOccurrences(of: "$(inherited)",
                                                                 with: existing)
                        return
                    }
                }
                accum[key] = value
            }
        }
    }
}

struct XCSourceInfo {
    let path: String
    let settings: [String: Any]?

    init(path: String, settings: [String: Any]?) {
        self.settings = settings
        self.path = Path(path).normalize().string
    }
}

struct XcodeTargetInfo {
    let name: String
    let hdrs: [String]
    let srcs: [XCSourceInfo]
    let resources: [String]
    let implicitResources: [String]
    let settings: [XCSettings]
    let linkedLibs: [String]
    let deps: [String]
}

/// Given a PBXFileElement, expand it to the tree.
/// It'd probably be more effetive to walk down the tree and unwrap these at
/// once, but this is very simple.
func unwrapPath(file: PBXFileElement) -> String? {
    func _unwrapPath(file: PBXFileElement) -> String? {
        guard let parent = file.parent else {
            return file.path
        }
        if let root = _unwrapPath(file: parent) {
            if let path = file.path {
                return root + "/" + path
            } else {
                return root
            }
        }
        return file.path
    }
    return _unwrapPath(file: file)
}

struct SourcePartition {
    let name: String
    let deps: [String]
    let sources: [XCSourceInfo]

    static let NoSettingsToken = "__"

    static func with(targetInfo: XcodeTargetInfo, predicate: (XCSourceInfo) -> Bool) -> [SourcePartition] {
        let partI = getSources(targetInfo: targetInfo, predicate: predicate)
        return partI.keys.sorted { $0 < $1 }.enumerated().map {
            idx, key -> SourcePartition in
            let partition = getPartition(idx: idx, keys: Array(partI.keys), name: targetInfo.name)
            let srcInfos: [XCSourceInfo] = partI[key]!
            return SourcePartition(
                name: targetInfo.name + partition.0,
                deps: targetInfo.deps + partition.1,
                sources: srcInfos.sorted { $0.path < $1.path }
            )
        }.sorted { $0.name < $1.name }
    }

    static func getSources(targetInfo: XcodeTargetInfo, predicate: (XCSourceInfo) -> Bool) -> [String: [XCSourceInfo]] {
        /// We need to partition out the sources
        var objcSrc: [String: [XCSourceInfo]] = [:]
        targetInfo.srcs.forEach {
            info in
            let key = getSettingsKey(settings: info.settings ?? [NoSettingsToken: NoSettingsToken])
            if predicate(info) {
                var val = objcSrc[key] ?? []
                val.append(info)
                objcSrc[key] = val
            }
        }
        return objcSrc
    }

    /// Returns the add name
    private static func getPartition(idx: Int, keys: [String], name _: String) -> (String, [String]) {
        let addName: String
        if idx == 0 {
            addName = ""
        } else {
            addName = "_\(idx)"
        }
        return (addName, [])
    }

    private static func getSettingsKey(settings: [String: Any]) -> String {
        return settings.values.reduce([String]()) {
            accum, next in
            if let s = next as? String {
                return accum + [s]
            }
            return accum
        }.joined(separator: "_")
    }
}

public func normalizedGlob(_ paths: [String]) -> GlobNode {
    return GlobNode(include: Set(normalizedPaths(paths)))
}

public func normalizedPaths(_ paths: [String]) -> [String] {
    // Same as below but memoized
    let srcRoot = Path(Options.shared.projectDir)
        .absolute().string + "/"
    return paths.map {
        v -> String in
        Path(v).absolute().string.replacingOccurrences(of: srcRoot, with: "")
    }
}

public func projectRelativePath(_ path: String) -> String {
    let wsSlashes = Options.shared.workspaceDir.split(separator: "/").count
    let projSlashes = Options.shared.projectDir.split(separator: "/").count
    let delta = projSlashes - wsSlashes
    let parts = path.split(separator: "/")
    return String(parts[delta ..< parts.count].joined(separator: "/"))
}

class Options {
    public static let shared = Options()

    lazy var workspaceDir: String = {
        FileManager.default.currentDirectoryPath
    }()

    lazy var projectDir: String = {
        (Path(self.projectArg) + Path("..")).absolute().string
    }()

    lazy var projectArg: String = {
        CommandLine.arguments[1]
    }()
}

let ToolchainCopts = [
    "-Wnon-modular-include-in-framework-module",
    "-g",
    "-stdlib=libc++",
    "-DCOCOAPODS=1",
    "-DOBJC_OLD_DISPATCH_PROTOTYPES=0",
    "-fdiagnostics-show-note-include-stack",
    "-fno-common",
    "-fembed-bitcode-marker",
    "-fmessage-length=0",
    "-fpascal-strings",
    "-fstrict-aliasing",
    "-Wno-error=nonportable-include-path",
]

struct XCBuildFile {
    let infos: [XcodeTargetInfo]

    func getTargets() -> [[BazelTarget]] {
        let sortedInfos = infos.sorted { $0.name < $1.name }

        // keeps track of collected libs
        var collectedLibs: Set<String> = Set()

        return sortedInfos.compactMap {
            targetInfo -> [BazelTarget] in
            // We need to partition out the sources to handle subsets of config
            // settings. Longer term, once rules_cc is done, we can replace
            // this with implementing _per file_ compilation actions.
            let objcSrcs = SourcePartition.with(targetInfo: targetInfo) {
                info in
                // Cocoapods sticks dummy files in here which is irrelevant with Bazel.
                // It ends up adding a lot of extra libs due to the way that partition them.
                // Longer term, when we're on rules_cpp and per-file compilation this should go
                if info.path.contains("Target Support Files") && info.path.hasSuffix("-dummy.m") {
                    return false
                }
                return info.path.hasSuffix(".m") ||
                    info.path.hasSuffix(".c") ||
                    info.path.hasSuffix(".s") ||
                    info.path.hasSuffix(".S")
            }
            let cppSrcs = SourcePartition.with(targetInfo: targetInfo) {
                info in
                info.path.hasSuffix(".mm") ||
                    info.path.hasSuffix(".cpp") ||
                    info.path.hasSuffix(".cxx") ||
                    info.path.hasSuffix(".cc")
            }

            let swiftSrcs = SourcePartition.with(targetInfo: targetInfo) {
                info in
                info.path.hasSuffix(".swift")
            }

            let name = targetInfo.name
            let info = targetInfo
            let hdrs = AttrSet(basic: normalizedGlob(info.hdrs))
            let targetSettings = XCSettings.merge(settings: targetInfo.settings)
            let productModuleName = targetSettings["PRODUCT_MODULE_NAME"] as? String ?? name
            let prefixHeader = targetSettings["GCC_PREFIX_HEADER"] as? String ?? ""
            let headerName = AttrSet(basic: productModuleName)
            let includes: [String] = []
            let deps = AttrSet(basic: info.deps)

            let headerSearchPaths = (targetSettings["HEADER_SEARCH_PATHS"] as? String)?
                .split(separator: " ").compactMap {
                    XCSettings.expand(String($0), settings: targetSettings)
                } ?? []

            let frameworkSearchPaths = (targetSettings["FRAMEWORK_SEARCH_PATHS"] as? String)?
                .split(separator: " ").compactMap {
                    XCSettings.expand(String($0), settings: targetSettings)
                } ?? []

            let librarySearchPaths = (targetSettings["LIBRARY_SEARCH_PATHS"] as? String)?
                .split(separator: " ").compactMap {
                    XCSettings.expand(String($0), settings: targetSettings)
                } ?? []

            let ldFlags = (targetSettings["OTHER_LDFLAGS"] as? String)?
                .split(separator: " ").compactMap {
                    XCSettings.expand(String($0), settings: targetSettings)
                } ?? []

            // TODO: MODULE_MAP_FILE
            let sdkRootVar = targetSettings["SDKROOT"] as? String ?? "<unknown>"

            // HACK! Consider calling `xcode-select` or something
            let developerDir = "/Applications/Xcode.app/Contents/Developer"
            let sdkRoot = "\(developerDir)/Platforms/\(sdkRootVar).platform/Developer/SDKs/\(sdkRootVar).sdk/"

            // Lookup frameworks and dylibs from the SDKRoot
            let frameworks = ldFlags.enumerated().reduce(into: [String]()) {
                accum, next in
                let idx = next.0
                let name = next.1
                if name == "-framework" {
                    accum.append(ldFlags[idx + 1])
                }
            }

            let sdkFrameworksPath = "\(sdkRoot)/System/Library/Frameworks"
            let sdkFrameworks = ldFlags.enumerated().reduce(into: [String]()) {
                accum, next in
                let idx = next.0
                let name = next.1
                if name == "-framework" {
                    let name = ldFlags[idx + 1]
                    let maybePath = sdkFrameworksPath + "/" + name + ".framework"
                    if FileManager.default.fileExists(atPath: maybePath) {
                        accum.append(name)
                    }
                }
            }
            let weakSdkFrameworks = ldFlags.enumerated().reduce(into: [String]()) {
                accum, next in
                let idx = next.0
                let name = next.1
                if name == "-weak_framework" {
                    let name = ldFlags[idx + 1]
                    let maybePath = sdkFrameworksPath + "/" + name + ".framework"
                    if FileManager.default.fileExists(atPath: maybePath) {
                        accum.append(name)
                    }
                }
            }

            let sdkLibPath = "\(sdkRoot)/usr/lib"
            let sdkDylibs = ldFlags.reduce(into: [String]()) {
                accum, next in
                let name = next
                if name.hasPrefix("-l") {
                    let libName = String(name.dropFirst().dropFirst())
                    let maybePath = sdkLibPath + "/lib" + libName + ".tbd"
                    if FileManager.default.fileExists(atPath: maybePath) {
                        accum.append(libName)
                    }
                }
            }

            // Lookup binaries from the source tree
            // e.g. for GoogleSignIn, we'd end up with a framework in GoogleSignIn/Frameworks
            // $(inherited) "${PODS_ROOT}/GoogleSignIn/Frameworks"

            // Note: we currently assume that the source root for cocoapods.
            // this should be added as a param for a fully generalized setup.
            // All include paths and search paths will expand from here
            // regardless of build file location.
            let workspaceRoot = Options.shared.workspaceDir + "/"

            let frameworkPaths = frameworks.compactMap {
                framework -> String? in
                for path in frameworkSearchPaths {
                    let maybePath = path + "/" + framework + ".framework"
                    if FileManager.default.fileExists(atPath: workspaceRoot + maybePath) {
                        return projectRelativePath(maybePath)
                    }
                }
                return nil
            }

            let vendoredFrameworks: [BazelTarget] = frameworkPaths.reduce(into: [BazelTarget]()) {
                accum, next in
                if collectedLibs.contains(next) {
                    return
                }
                collectedLibs.insert(next)

                let frameworkPath = next
                let frameworkName = String(String(frameworkPath.split(separator: "/").last!)
                    .split(separator: ".").first!)
                let ruleName = "\(frameworkName)_VendoredFrameworks"
                // FIXME: determine if this is static or not
                let pathImport = AppleStaticFrameworkImport(name: ruleName,
                                                            frameworkImports: AttrSet(basic: [frameworkPath]))

                let hdrs = GlobNode(include: Set([frameworkPath + "/Headers/**"]))
                let lib = ObjcLibrary(name: frameworkName, externalName: frameworkName,
                                      sourceFiles: AttrSet.empty, headers: AttrSet(basic: hdrs),
                                      headerName: AttrSet.empty, moduleMap: nil, prefixHeader: "",
                                      includes: [], sdkFrameworks: AttrSet.empty,
                                      weakSdkFrameworks: AttrSet.empty, sdkDylibs:
                                      AttrSet(basic: sdkDylibs), deps: AttrSet(basic: [ruleName]),
                                      copts: AttrSet.empty, bundles: AttrSet.empty,
                                      resources: AttrSet.empty, publicHeaders: AttrSet.empty,
                                      nonArcSrcs: AttrSet.empty, requiresArc: AttrSet.empty,
                                      isTopLevelTarget: false)
                accum.append(lib)
                accum.append(pathImport)
            }

            let libraries = ldFlags.reduce(into: [String]()) {
                accum, next in
                let name = next
                if name.hasPrefix("-l") {
                    let libName = String(name.dropFirst().dropFirst())
                    accum.append(libName)
                }
            }

            let libraryPaths = libraries.compactMap {
                library -> String? in
                for path in librarySearchPaths {
                    let maybePath = path + "/lib" + library + ".a"
                    if FileManager.default.fileExists(atPath: workspaceRoot + maybePath) {
                        return projectRelativePath(maybePath)
                    }
                }
                return nil
            }
            let vendoredLibraries: [BazelTarget] = libraryPaths.reduce(into: [BazelTarget]()) {
                accum, next in
                if collectedLibs.contains(next) {
                    return
                }
                collectedLibs.insert(next)

                let libPath = next
                // Extract the lib name from the path `lib${SOME}.a`
                let baseName = String(libPath.split(separator: "/").last!)
                let libName = String(baseName
                    .split(separator: ".").first!.dropFirst().dropFirst().dropFirst())
                let ruleName = "\(libName)_VendoredLibraries"
                let pathImport = ObjcImport(name: ruleName, archives:
                    AttrSet(basic: [libPath]))
                let hdrs = GlobNode(include: Set([libPath + "/Headers/**"]))
                let lib = ObjcLibrary(name: libName, externalName: libName,
                                      sourceFiles: AttrSet.empty, headers: AttrSet(basic: hdrs),
                                      headerName: AttrSet.empty,
                                      moduleMap: nil,
                                      prefixHeader: "",
                                      includes: [], sdkFrameworks: AttrSet(basic: sdkFrameworks),
                                      weakSdkFrameworks: AttrSet(basic: weakSdkFrameworks), sdkDylibs:
                                      AttrSet(basic: sdkDylibs), deps: AttrSet(basic: [ruleName]),
                                      copts: AttrSet.empty, bundles: AttrSet.empty,
                                      resources: AttrSet.empty, publicHeaders: AttrSet.empty,
                                      nonArcSrcs: AttrSet.empty, requiresArc: AttrSet.empty,
                                      isTopLevelTarget: false)
                accum.append(lib)
                accum.append(pathImport)
            }

            var extendedModuleMap: ModuleMap?
            var moduleMap: ModuleMap?
            var moduleMaps: [BazelTarget] = []
            if swiftSrcs.count > 0 {
                // Extend the module map
                extendedModuleMap = ModuleMap(
                    name: name,
                    dirname: name + "_extended_module_map",
                    moduleName: productModuleName,
                    headers: [name + "_hdrs"],
                    swiftHeader: "../" + name + "-Swift.h"
                )

                moduleMap = ModuleMap(
                    name: name,
                    dirname: name + "_module_map",
                    moduleName: productModuleName,
                    headers: [name + "_extended_module_map_module_map_file", name + "_hdrs"],
                    moduleMapName: name + ".modulemap"
                )
                moduleMaps.append(extendedModuleMap!)
                moduleMaps.append(moduleMap!)
            }

            let objcLibs: [BazelTarget] = objcSrcs.map {
                partition -> BazelTarget in
                let deps = partition.deps
                // Note: if arc is in here then we've got an arc only lib.
                // there is no dealing with splitting out sources.
                // there's a thing about cocoapods where you need to specify
                // per subspec copts, and that is also taken into account by
                // partitioning / per file copts.
                let copts: [String] = {
                    if let settings = partition.sources.first?.settings {
                        return settings.values.compactMap { $0 as? String }
                    }
                    return []
                }() + ToolchainCopts + headerSearchPaths.map { "-I" + $0 } + [
                    "-fobjc-weak",
                ]

                var extraDeps: [String] = []
                let isTopLevelTarget = partition.name == name
                if isTopLevelTarget {
                    // When there is multiple source types, the objc library _is_ the top level
                    let additionalObjcLibs = objcSrcs.dropFirst()
                    extraDeps.append(contentsOf: additionalObjcLibs.map { $0.name })
                    extraDeps.append(contentsOf: cppSrcs.map { $0.name + "_cxx" })
                    extraDeps.append(contentsOf: swiftSrcs.map { $0.name + "_swift" })
                    // Consider cleaning this up to not include the "_import" rules
                    extraDeps.append(contentsOf: vendoredLibraries.map { $0.name })
                    extraDeps.append(contentsOf: vendoredFrameworks.map { $0.name })
                }
                let sources = AttrSet(basic: normalizedGlob(partition.sources.map { $0.path }))
                let resources = AttrSet(basic: normalizedGlob(targetInfo.implicitResources))
                return ObjcLibrary(name: partition.name, externalName: partition.name,
                                   sourceFiles: sources, headers: hdrs,
                                   headerName: headerName, moduleMap:
                                   extendedModuleMap ?? moduleMap, prefixHeader: prefixHeader,
                                   includes: includes, sdkFrameworks: AttrSet(basic: sdkFrameworks),
                                   weakSdkFrameworks: AttrSet(basic: weakSdkFrameworks), sdkDylibs:
                                   AttrSet(basic: sdkDylibs), deps: AttrSet(basic: deps + extraDeps),
                                   copts: AttrSet(basic: copts), bundles: AttrSet.empty,
                                   resources: resources, publicHeaders: AttrSet.empty,
                                   nonArcSrcs: AttrSet.empty, requiresArc: AttrSet.empty,
                                   isTopLevelTarget: isTopLevelTarget)
            }

            let cppLibs: [BazelTarget] = cppSrcs.map {
                partition -> BazelTarget in
                let deps = AttrSet(basic: partition.deps)
                let copts: [String] = {
                    if let settings = partition.sources.first?.settings {
                        return settings.values.compactMap { $0 as? String }
                    }
                    return []
                }() + ToolchainCopts + [
                    "-stdlib=libc++",
                    "-std=c++14",
                ] + headerSearchPaths.map { "-I" + $0 }

                let sources = AttrSet(basic: normalizedGlob(partition.sources.map { $0.path }))
                let addName = (objcLibs.count > 0) ? "_cxx" : ""
                let resources = AttrSet(basic: normalizedGlob(targetInfo.implicitResources))
                return ObjcLibrary(name: partition.name + addName, externalName: name + addName,
                                   sourceFiles: sources, headers: hdrs,
                                   headerName: headerName,
                                   moduleMap: extendedModuleMap ?? moduleMap,
                                   prefixHeader:
                                   prefixHeader, includes: includes,
                                   sdkFrameworks: AttrSet(basic: sdkFrameworks), weakSdkFrameworks:
                                   AttrSet(basic: weakSdkFrameworks), sdkDylibs: AttrSet.empty, deps:
                                   deps, copts: AttrSet(basic: copts), bundles: AttrSet.empty, resources:
                                   resources, publicHeaders: AttrSet.empty,
                                   nonArcSrcs: AttrSet.empty, requiresArc: AttrSet.empty,
                                   isTopLevelTarget: objcLibs.count == 0 && partition.name == name)
            }

            let swiftLibs: [BazelTarget] = swiftSrcs.map {
                partition -> BazelTarget in
                let deps = AttrSet(basic: partition.deps)
                let sources = AttrSet(basic: normalizedGlob(partition.sources.map { $0.path }))
                let addName = (objcLibs.count > 0) ? "_swift" : ""
                let resources = AttrSet(basic: normalizedGlob(targetInfo.implicitResources))
                guard let moduleMap = moduleMap else {
                    fatalError("missing modulemap")
                }
                let copts = headerSearchPaths.reduce(into: [String]()) {
                    accum, next in
                    accum.append("-Xcc")
                    accum.append("-I" + next)
                }
                return SwiftLibrary(name: partition.name + addName,
                                    sourceFiles: sources,
                                    moduleMap: moduleMap,
                                    deps: deps,
                                    copts: AttrSet(basic: copts),
                                    swiftcInputs: AttrSet.empty,
                                    isTopLevelTarget: partition.name == name,
                                    externalName: name,
                                    data: resources)
            }

            let bundles: [BazelTarget]
            // HACK!: This assumes that we're using cocoapods Xcode projects
            // where there is a target for bundles
            if targetInfo.resources.count > 0 {
                bundles = [
                    AppleResourceBundle(name: targetInfo.name, resources:
                        AttrSet(basic: normalizedPaths(targetInfo.resources))),
                ]
            } else {
                bundles = []
            }
            var srcLibs = cppLibs + objcLibs + swiftLibs + bundles
            if srcLibs.count == 0 {
                var extraDeps: [String] = []
                // Consider cleaning this up to not include the "_import" rules
                extraDeps.append(contentsOf: vendoredLibraries.map { $0.name })
                extraDeps.append(contentsOf: vendoredFrameworks.map { $0.name })

                srcLibs.append(ObjcLibrary(name: targetInfo.name, externalName: targetInfo.name,
                                           sourceFiles: AttrSet.empty, headers: hdrs,
                                           headerName: AttrSet.empty,
                                           moduleMap: extendedModuleMap ?? moduleMap,
                                           prefixHeader: "",
                                           includes: [], sdkFrameworks: AttrSet.empty,
                                           weakSdkFrameworks: AttrSet.empty, sdkDylibs:
                                           AttrSet.empty, deps: deps <> AttrSet(basic: extraDeps),
                                           copts: AttrSet.empty, bundles: AttrSet.empty,
                                           resources: AttrSet.empty, publicHeaders: AttrSet.empty,
                                           nonArcSrcs: AttrSet.empty, requiresArc: AttrSet.empty,
                                           isTopLevelTarget: false))
            }
            let binLibs = vendoredFrameworks + vendoredLibraries
            return (srcLibs + binLibs + moduleMaps).sorted { $0.name < $1.name }
        }
    }

    func toSkylark() -> SkylarkNode {
        let targets = getTargets()
        var flattenedTargets: [BazelTarget] = []
        for lib in targets {
            for liblib in lib {
                flattenedTargets.append(liblib)
            }
        }

        let skylark = flattenedTargets.map { $0.toSkylark() }
        /* Note: there seems to be an issue with conditonal casting here.
         makeLoadNodes(forConvertibles: libs.compactMap { $0 as? SkylarkConvertible }),
         */
        let loadNodes = SkylarkNode.lines([
            .skylark("load('@build_bazel_rules_swift//swift:swift.bzl', 'swift_library')"),
            .skylark("load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_bundle_import')"),
            .skylark("load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_resource_bundle')"),
            .skylark("load('@build_bazel_rules_apple//apple:apple.bzl', 'apple_static_framework_import')"),
        ])

        return .lines([
            makePrefixNodes(),
            loadNodes,
            .lines(skylark),
        ])
    }

    /// This is kind of a hack for Cocoapods. They use a shell script to
    /// install resources, and arbitrary shell scripts don't map to Bazel well
    /// because of build system directory structure. Assume that all adjacent
    /// resources belong in the target for now. Perhaps longer term it could
    /// read the resources phase in the installed project's targets.
    private static func getImplicitResources(target: PBXTarget, sourceFiles:
        [PBXFileElement], resources: [PBXFileElement]) -> [PBXFileElement] {
        let parents = sourceFiles.reduce(into: Set<PBXGroup>()) {
            accum, next in
            if let group = next.parent as? PBXGroup {
                accum.insert(group)
            }
        }
        // BFS for "Resources" directory, which is a convention in this setting
        let adjacentResources = parents.reduce(into: Set<PBXFileElement>()) {
            accum, next in
            var queue: [PBXFileElement] = [next]
            repeat {
                let first = queue.first!
                queue = Array(queue.dropFirst())
                if let firstGroup = first as? PBXGroup {
                    queue.append(contentsOf: firstGroup.children)
                    if firstGroup.name == "Resources" {
                        firstGroup.children.forEach { accum.insert($0) }
                    }
                }
            } while queue.count > 0
        }

        /// Don't include resources from dep build phases..
        let dependentResources = target.dependencies.reduce(into: Set<PBXFileElement>()) {
            accum, next in
            next.target?.buildPhases.forEach {
                buildPhase in
                if let resourcesBuildPhase = buildPhase as? PBXResourcesBuildPhase {
                    resourcesBuildPhase.files?.forEach { accum.insert($0.file!) }
                }
            }
        }
        let unbundledResources = Set(adjacentResources)
            .subtracting(Set(sourceFiles))
            .subtracting(Set(resources))
            .subtracting(Set(dependentResources))
        return Array(unbundledResources)
    }

    /// Instantiats a build file from an XcodeProj
    static func fromProj(xcodeproj: XcodeProj) -> XCBuildFile {
        var buildFilesByKey = [PBXFileElement: PBXBuildFile]()
        xcodeproj.pbxproj.buildFiles.forEach {
            buildFile in
            if let fileRef = buildFile.file {
                buildFilesByKey[fileRef] = buildFile
            }
        }

        // Extracts `XCTargetInfo` from all of the native targets
        let nativeTargets = xcodeproj.pbxproj.nativeTargets
        let infos = nativeTargets.compactMap {
            target -> XcodeTargetInfo? in
            var hdrs: [PBXFileElement] = []
            var resources: [PBXFileElement] = []
            var frameworks: [PBXFileElement] = []
            target.buildPhases.forEach {
                buildPhase in
                if let headersBuildPhase = buildPhase as? PBXHeadersBuildPhase {
                    hdrs = headersBuildPhase.files?.compactMap { $0.file } ?? []
                }
                if let resourcesBuildPhase = buildPhase as? PBXResourcesBuildPhase {
                    resources = resourcesBuildPhase.files?.compactMap { $0.file } ?? []
                }
                if let frameworksBuildPhase = buildPhase as? PBXFrameworksBuildPhase {
                    frameworks = frameworksBuildPhase.files?.compactMap { $0.file } ?? []
                }
            }

            let sourceFiles = (try? target.sourceFiles()) ?? []
            let implicitResources = getImplicitResources(target: target,
                                                         sourceFiles: sourceFiles,
                                                         resources: resources)
            var settings: [XCSettings] = []
            if let configList = target.buildConfigurationList {
                settings = configList.buildConfigurations.compactMap {
                    config -> XCSettings in
                    if let base: PBXFileReference = config.baseConfiguration {
                        return XCSettings(basePath: unwrapPath(file: base),
                                          settings: config.buildSettings)
                    }
                    return XCSettings(basePath: nil, settings: config.buildSettings)
                }
            }

            let srcInfos = sourceFiles.compactMap {
                info -> XCSourceInfo in
                let settings = buildFilesByKey[info]?.settings ?? [:]
                return XCSourceInfo(path: unwrapPath(file: info) ?? "",
                                    settings: settings)
            }

            return XcodeTargetInfo(
                name: target.name,
                hdrs: hdrs.compactMap(unwrapPath),
                srcs: srcInfos,
                resources: resources.compactMap(unwrapPath),
                implicitResources: implicitResources.compactMap(unwrapPath),
                settings: settings,
                linkedLibs: frameworks.compactMap(unwrapPath),
                deps: target.dependencies.compactMap { dep in
                    dep.name ?? dep.target?.name
                }
            )
        }
        return XCBuildFile(infos: infos)
    }
}

func main() {
    guard CommandLine.arguments.count == 2 else {
        let arg0 = Path(CommandLine.arguments[0]).lastComponent
        fputs("usage: \(arg0) <project> \n", stderr)
        exit(1)
    }

    do {
        let projectArg = CommandLine.arguments[1]
        print("# Generated for project \(projectArg)")
        _ = Options.shared.workspaceDir
        let projectDir = Options.shared.projectDir
        let projectPath = Path(projectArg).absolute()
        guard FileManager.default.changeCurrentDirectoryPath(projectDir) else {
            fatalError("Can't change path to project dir" + String(describing: projectDir))
        }

        let xcodeproj = try XcodeProj(path: projectPath)
        let buildFile = XCBuildFile.fromProj(xcodeproj: xcodeproj)
        let buildFileSkylarkCompiler = SkylarkCompiler(buildFile.toSkylark())
        let buildFileOut = buildFileSkylarkCompiler.run()
        print(buildFileOut)
    } catch {
        print(error)
    }
}

main()
