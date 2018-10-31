load("@build_bazel_rules_apple//apple:swift.bzl", "swift_library")
load("@build_bazel_rules_apple//apple:macos.bzl", "macos_command_line_application")

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
    deps = [":ObjcSupport"],
    copts = ["-swift-version", "4", "-static-stdlib"],
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
)

swift_library(
    name = "RepoToolsCore",
    srcs = glob(["Sources/RepoToolsCore/*.swift"]),
    deps = [":PodToBUILD"],
    copts = ["-swift-version", "4", "-static-stdlib"],
)

alias(name = "update_pods", actual = "//bin:update_pods")

