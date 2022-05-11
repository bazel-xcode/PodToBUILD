//
//  BuildOptions.swift
//  PodToBUILD
//
//  Created by Jerry Marino on 3/25/2020.
//  Copyright © 2020 Pinterest Inc. All rights reserved.

public protocol BuildOptions {
    var userOptions: [String] { get }
    var globalCopts: [String] { get }
    var trace: Bool { get }
    var podName: String { get }
    var path: String { get }
    var revision: String { get }

    // Frontend options

    var enableModules: Bool { get }
    var generateModuleMap: Bool { get }
    var generateHeaderMap: Bool { get }

    // pod_support, everything, none
    var headerVisibility: String { get }
    
    var alwaysSplitRules: Bool { get }
    var vendorize: Bool { get }
    var childPaths: [String] { get }
    var isDynamicFramework: Bool { get }
}

public struct BasicBuildOptions: BuildOptions {
    public let podName: String
    public let path: String
    public let userOptions: [String]
    public let globalCopts: [String]
    public let trace: Bool
    public let revision: String

    public let enableModules: Bool
    public let generateModuleMap: Bool
    public let generateHeaderMap: Bool
    public let headerVisibility: String
    public let alwaysSplitRules: Bool
    public let vendorize: Bool
    public let childPaths: [String]
    public let isDynamicFramework: Bool

    public init(podName: String = "",
                path: String = ".",
                userOptions: [String] = [],
                globalCopts: [String] = [],
                trace: Bool = false,
                revision: String = "",
                enableModules: Bool = false,
                generateModuleMap: Bool = false,
                generateHeaderMap: Bool = false,
                headerVisibility: String = "",
                alwaysSplitRules: Bool = true,
                vendorize: Bool = true,
                childPaths: [String] = [],
                isDynamicFramework: Bool = false
    ) {
        self.podName = podName
        self.path = path
        self.userOptions = userOptions
        self.globalCopts = globalCopts
        self.trace = trace
        self.revision = revision
        self.enableModules = enableModules
        self.generateModuleMap = generateModuleMap
        self.generateHeaderMap = generateHeaderMap
        self.headerVisibility = headerVisibility
        self.alwaysSplitRules = alwaysSplitRules
        self.vendorize = vendorize
        self.childPaths = childPaths
        self.isDynamicFramework = isDynamicFramework
    }

    public static let empty = BasicBuildOptions(podName: "")
}
