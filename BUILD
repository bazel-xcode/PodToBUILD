load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application", "macos_unit_test")

objc_library(
    name = "ObjcSupport",
    srcs = glob(["Sources/ObjcSupport/*.m"]),
    hdrs = glob(["Sources/ObjcSupport/include/*"]),
    includes = ["Sources/ObjcSupport/include"]
)

# PodToBUILD is a core library enabling Skylark code generation
swift_library(
    name = "PodToBUILD",
    srcs = glob(["Sources/PodToBUILD/*.swift"]),
    deps = [":ObjcSupport", "@podtobuild-Yams//:Yams"],
    copts = ["-swift-version", "5"],
)

# Compiler
macos_command_line_application(
    name = "Compiler",
    minimum_os_version = "10.13",
    deps = [":CompilerLib"],
)

swift_library(
    name = "CompilerLib",
    srcs = glob(["Sources/Compiler/*.swift"]),
    deps = [":PodToBUILD"],
    copts = ["-swift-version", "5"],
)

# RepoTools
macos_command_line_application(
    name = "RepoTools",
    minimum_os_version = "10.13",
    deps = [":RepoToolsLib"],
)

swift_library(
    name = "RepoToolsLib",
    srcs = glob(["Sources/RepoTools/*.swift"]),
    deps = [":RepoToolsCore"],
    copts = ["-swift-version", "5"],
)

swift_library(
    name = "RepoToolsCore",
    srcs = glob(["Sources/RepoToolsCore/*.swift"]),
    deps = [":PodToBUILD"],
    copts = ["-swift-version", "4"],
)

alias(name = "update_pods", actual = "//bin:update_pods")

# This tests RepoToolsCore and Skylark logic
swift_library(
    name = "PodToBUILDTestsLib",
    srcs = glob(["Tests/PodToBUILDTests/*.swift"]),
    deps = [":RepoToolsCore", "@podtobuild-SwiftCheck//:SwiftCheck"],
    data = glob(["Examples/**/*.podspec.json"])
)

macos_unit_test(
    name = "PodToBUILDTests",
    deps = [":PodToBUILDTestsLib"],
    minimum_os_version = "10.13",
)

swift_library(
    name = "BuildTestsLib", 
    srcs = glob(["Tests/BuildTests/*.swift"]),
    deps = [":RepoToolsCore", "@podtobuild-SwiftCheck//:SwiftCheck"],
    data = glob(["Examples/**/*.podspec.json"])
)

# This tests RepoToolsCore and Skylark logic
macos_unit_test(
    name = "BuildTests",
    deps = [":BuildTestsLib"],
    minimum_os_version = "10.13",
)

