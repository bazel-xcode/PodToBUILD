load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@rules_cc//cc:defs.bzl", "objc_library")

package(default_visibility = ["//visibility:public"])

ios_application(
    name = "ios-app",
    bundle_id = "com.Frankenstein",
    families = ["iphone"],
    infoplists = ["ios-app/Info.plist"],
    visibility = ["//visibility:public"],
    deps = ["ios-app-bin"],
    minimum_os_version = "9.3"
)

objc_library(
    name = "ios-app-bin",
    srcs = glob([
        "ios-app/*.m",
    ]),
    hdrs = glob([
        "ios-app/*.h",
    ]),
    includes = ["ios-app"],
    enable_modules = True,
    deps = [
        "//:all",
    ],
    sdk_frameworks = ["UIKit", "CoreGraphics"]
)

