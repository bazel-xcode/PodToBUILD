// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PodToBUILD",
    platforms: [
        .macOS(.v10_12),
    ],
    products: [
        // PodToBUILD is a core library enabling Skylark code generation
        .library(
            name: "PodToBUILD",
            targets: ["Compiler",  "RepoTools"]),
        .library(
            name: "ObjcSupport",
            targets: ["PodToBUILD"]),
        .library(
            name: "RepoToolsCore",
            targets: ["RepoTools"]),
    ],
    dependencies: [
         .package(url: "https://github.com/typelift/SwiftCheck.git",
                  from: "0.10.0")
    ],
    targets: [
        .target(
            name: "PodToBUILD",
            dependencies: ["ObjcSupport"]),
        .target(
            name: "ObjcSupport",
            dependencies: []),
        // Basic buildfile compiler. Mainly used for internal testing.
        .target(
            name: "Compiler",
            dependencies: ["PodToBUILD"]),

        // Core Bootstrap tool
        .target(
            name: "RepoToolsCore",
            dependencies: ["PodToBUILD"]),
        .target(
            name: "RepoTools",
            dependencies: ["RepoToolsCore"]),

        // This tests RepoToolsCore and Skylark logic
        .testTarget(
            name: "PodToBUILDTests",
            dependencies: ["RepoToolsCore", "SwiftCheck"]),
        .testTarget(
            name: "BuildTests",
            // We only depend on this for the shell lib.
            // TODO: Factor that out.
            dependencies: ["RepoToolsCore"]),
    ]
)
