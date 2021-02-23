load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@rules_cc//cc:defs.bzl", "objc_library")

# This is needed for implicit entitlement rules created for
# files.
package(default_visibility = ["//visibility:public"])

ios_application(
    name = "ios-app",
    bundle_id = "com.Frankenstein",
    families = ["iphone"],
    infoplists = ["Info.plist"],
    visibility = ["//visibility:public"],
    deps = ["ios-app-bin"],
    minimum_os_version = "9.3"
)

objc_library(
    name = "ios-app-bin",
    srcs = [
        "main.m",
    ],
    enable_modules = True,
    deps = [
        "@SlackTextViewController//:SlackTextViewController",
    ],
    sdk_frameworks = ["UIKit", "CoreGraphics"]
)

