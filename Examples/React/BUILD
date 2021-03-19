load("@build_bazel_rules_apple//apple:ios.bzl", "ios_application")
load("@rules_cc//cc:defs.bzl", "objc_library")

objc_library(
    name = "AppClasses",
    srcs = [
        "App/AppDelegate.m",
        "App/main.m",
    ],
    hdrs = glob(["App/*.h"]),
    sdk_frameworks = [
        "QuartzCore",
        "CFNetwork",
        "CoreGraphics",
        "ImageIO",
        "Security",
        "Accelerate",
    ],
    deps = [
        "//Vendor/React",
        "//Vendor/React:React_hmap",
    ],
    copts = [
        "-I$(GENDIR)/Vendor/React/React_hmap.hmap",
        "-I."
    ],
)

ios_application(
    name = "ReactNativeApp",
    bundle_id = "example.app",
    families = [
        "iphone",
    ],
    infoplists = ["App/Info.plist"],
    minimum_os_version = "14.0",
    visibility = ["//visibility:public"],
    deps = [
        ":AppClasses",
    ],
)
