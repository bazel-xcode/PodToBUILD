load('@build_bazel_rules_apple//apple:resources.bzl', 'apple_bundle_import')
load(
  "//Vendor/rules_pods/BazelExtensions:extensions.bzl",
  "pch_with_name_hint",
  "acknowledged_target",
  "gen_module_map",
  "gen_includes",
  "headermap"
)
# Add a config setting release for compilation mode
# Assume that people are using `opt` for release mode
# see the bazel user manual for more information
# https://docs.bazel.build/versions/master/be/general.html#config_setting
config_setting(
  name = "release",
  values = {
    "compilation_mode": "opt"
  }
)
config_setting(
  name = "osxCase",
  values = {
    "apple_platform_type": "macos"
  }
)
config_setting(
  name = "tvosCase",
  values = {
    "apple_platform_type": "tvos"
  }
)
config_setting(
  name = "watchosCase",
  values = {
    "apple_platform_type": "watchos"
  }
)
filegroup(
  name = "FBSDKCoreKit_hdrs",
  srcs = glob(
    [
      "pod_support/Headers/Public/**/*"
    ],
    exclude_directories = 1
  ) + [
    ":Basics_hdrs",
    ":Core_hdrs"
  ],
  visibility = [
    "//visibility:public"
  ]
)
headermap(
  name = "FBSDKCoreKit_hmap",
  namespace = "FBSDKCoreKit",
  hdrs = [
    ":FBSDKCoreKit_hdrs"
  ],
  deps = [
    ":Basics",
    ":Core",
    ":Core_Bundle_FacebookSDKStrings"
  ],
  visibility = [
    "//visibility:public"
  ]
)
gen_includes(
  name = "FBSDKCoreKit_includes",
  include = [
    "Vendor/FBSDKCoreKit/pod_support/Headers/Public/"
  ]
)
gen_module_map(
  "FBSDKCoreKit",
  "FBSDKCoreKit_module_map",
  "FBSDKCoreKit",
  [
    "FBSDKCoreKit_hdrs"
  ]
)
objc_library(
  name = "FBSDKCoreKit",
  enable_modules = 0,
  srcs = glob(
    [
      "FBSDKCoreKit/FBSDKCoreKit/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/*.s",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
    ],
    exclude = glob(
      [
        "FBSDKCoreKit/FBSDKCoreKit/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/*.s",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
      ],
      exclude_directories = 1
    ),
    exclude_directories = 1
  ),
  non_arc_srcs = glob(
    [
      "FBSDKCoreKit/FBSDKCoreKit/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/*.s",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
      "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
    ],
    exclude = glob(
      [
        "FBSDKCoreKit/FBSDKCoreKit/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/*.s",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
        "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
      ],
      exclude_directories = 1
    ),
    exclude_directories = 1
  ),
  hdrs = [
    ":FBSDKCoreKit_hdrs"
  ],
  pch = pch_with_name_hint(
    "FBSDKCoreKit",
    glob(
      [
        "FBSDKCoreKit/**/*.pch"
      ],
      exclude_directories = 1
    )
  ),
  weak_sdk_frameworks = select(
    {
      "//conditions:default": [
        "Accounts",
        "CoreLocation",
        "Social",
        "Security",
        "QuartzCore",
        "CoreGraphics",
        "UIKit",
        "Foundation",
        "AudioToolbox"
      ],
      ":tvosCase": [
        "CoreLocation",
        "Security",
        "QuartzCore",
        "CoreGraphics",
        "UIKit",
        "Foundation",
        "AudioToolbox"
      ]
    }
  ),
  deps = [
    ":Basics",
    ":Core",
    ":Core_Bundle_FacebookSDKStrings",
    ":FBSDKCoreKit_includes"
  ],
  copts = select(
    {
      "//conditions:default": [
        "-DPOD_CONFIGURATION_RELEASE=0"
      ],
      ":release": [
        "-DPOD_CONFIGURATION_RELEASE=1",
        "-DNS_BLOCK_ASSERTIONS=1"
      ]
    }
  ) + [
    "-IVendor/FBSDKCoreKit/pod_support/Headers/Public/FBSDKCoreKit/"
  ] + [
    "-fmodule-name=FBSDKCoreKit_pod_module"
  ],
  visibility = [
    "//visibility:public"
  ]
)
acknowledged_target(
  name = "FBSDKCoreKit_acknowledgement",
  deps = [],
  value = "//Vendor/FBSDKCoreKit/pod_support_buildable:acknowledgement_fragment"
)
filegroup(
  name = "Basics_hdrs",
  srcs = glob(
    [
      "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.h",
      "FBSDKCoreKit/FBSDKCoreKit/Basics/*.h"
    ],
    exclude_directories = 1
  ),
  visibility = [
    "//visibility:public"
  ]
)
filegroup(
  name = "Basics_union_hdrs",
  srcs = [
    "Basics_hdrs",
    "FBSDKCoreKit_hdrs"
  ],
  visibility = [
    "//visibility:public"
  ]
)
headermap(
  name = "Basics_hmap",
  namespace = "FBSDKCoreKit",
  hdrs = [
    ":Basics_union_hdrs"
  ],
  deps = [],
  visibility = [
    "//visibility:public"
  ]
)
gen_includes(
  name = "Basics_includes",
  include = [
    "Vendor/FBSDKCoreKit/pod_support/Headers/Public/"
  ]
)
objc_library(
  name = "Basics",
  enable_modules = 0,
  srcs = select(
    {
      "//conditions:default": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
        ],
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
              ],
              exclude = [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*.m"
              ],
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":osxCase": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
        ],
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
              ],
              exclude = [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
              ],
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":tvosCase": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
        ],
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
              ],
              exclude = [
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/FBSDKHybridAppEventsScriptMessageHandler.m",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKMeasurementEvent.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKURL.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAudioResourceLoader.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKContainerViewController.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMonotonicTime.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKSystemAccountStoreAdapter.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKTriStateBOOL.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKCloseIcon.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKColor.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKMaleSilhouetteIcon.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.s"
              ],
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":watchosCase": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
        ],
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
              ],
              exclude = [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
              ],
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      )
    }
  ),
  non_arc_srcs = select(
    {
      "//conditions:default": glob(
        glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
            ],
            exclude = [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*.m"
            ],
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
              ],
              exclude = glob(
                [
                  "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
                ],
                exclude = [
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
                  "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.m",
                  "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*.m"
                ],
                exclude_directories = 1
              ),
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":osxCase": glob(
        glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
            ],
            exclude = [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
            ],
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
              ],
              exclude = glob(
                [
                  "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
                ],
                exclude = [
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
                ],
                exclude_directories = 1
              ),
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":tvosCase": glob(
        glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
            ],
            exclude = [
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/FBSDKHybridAppEventsScriptMessageHandler.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKMeasurementEvent.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKURL.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAudioResourceLoader.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKContainerViewController.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMonotonicTime.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKSystemAccountStoreAdapter.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKTriStateBOOL.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKCloseIcon.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKColor.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKMaleSilhouetteIcon.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.s"
            ],
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
              ],
              exclude = glob(
                [
                  "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
                ],
                exclude = [
                  "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.S",
                  "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.c",
                  "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cc",
                  "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cpp",
                  "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cxx",
                  "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.mm",
                  "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.s",
                  "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/FBSDKHybridAppEventsScriptMessageHandler.m",
                  "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
                  "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
                  "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
                  "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
                  "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
                  "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
                  "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
                  "FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.m",
                  "FBSDKCoreKit/FBSDKCoreKit/FBSDKMeasurementEvent.m",
                  "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.m",
                  "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.m",
                  "FBSDKCoreKit/FBSDKCoreKit/FBSDKURL.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.S",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.c",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cc",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cpp",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cxx",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.mm",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.s",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAudioResourceLoader.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKContainerViewController.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMonotonicTime.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKSystemAccountStoreAdapter.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKTriStateBOOL.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKCloseIcon.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKColor.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKMaleSilhouetteIcon.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.S",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.c",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cc",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cpp",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cxx",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.mm",
                  "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.s"
                ],
                exclude_directories = 1
              ),
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":watchosCase": glob(
        glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
            ],
            exclude = [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
            ],
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m"
              ],
              exclude = glob(
                [
                  "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
                ],
                exclude = [
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                  "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
                ],
                exclude_directories = 1
              ),
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      )
    }
  ),
  hdrs = [
    ":Basics_union_hdrs"
  ],
  pch = pch_with_name_hint(
    "FBSDKCoreKit",
    glob(
      [
        "FBSDKCoreKit/**/*.pch"
      ],
      exclude_directories = 1
    )
  ),
  weak_sdk_frameworks = select(
    {
      "//conditions:default": [
        "Accounts",
        "CoreLocation",
        "Social",
        "Security",
        "QuartzCore",
        "CoreGraphics",
        "UIKit",
        "Foundation",
        "AudioToolbox"
      ],
      ":tvosCase": [
        "CoreLocation",
        "Security",
        "QuartzCore",
        "CoreGraphics",
        "UIKit",
        "Foundation",
        "AudioToolbox"
      ]
    }
  ),
  sdk_dylibs = [
    "z"
  ],
  deps = [
    ":Basics_includes"
  ],
  copts = select(
    {
      "//conditions:default": [
        "-DPOD_CONFIGURATION_RELEASE=0"
      ],
      ":release": [
        "-DPOD_CONFIGURATION_RELEASE=1",
        "-DNS_BLOCK_ASSERTIONS=1"
      ]
    }
  ) + [
    "-IVendor/FBSDKCoreKit/pod_support/Headers/Public/FBSDKCoreKit/"
  ] + [
    "-fmodule-name=FBSDKCoreKit_pod_module"
  ],
  visibility = [
    "//visibility:public"
  ]
)
acknowledged_target(
  name = "Basics_acknowledgement",
  deps = [],
  value = "//Vendor/FBSDKCoreKit/pod_support_buildable:acknowledgement_fragment"
)
apple_bundle_import(
  name = "Core_Bundle_FacebookSDKStrings",
  bundle_imports = glob(
    [
      "FacebookSDKStrings.bundle/**"
    ],
    exclude_directories = 1
  )
)
acknowledged_target(
  name = "Core_Bundle_FacebookSDKStrings_acknowledgement",
  deps = [],
  value = "//Vendor/FBSDKCoreKit/pod_support_buildable:acknowledgement_fragment"
)
filegroup(
  name = "Core_hdrs",
  srcs = select(
    {
      "//conditions:default": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/**/*.h"
        ],
        exclude = [
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.hpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.hxx",
          "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.h",
          "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*.h"
        ],
        exclude_directories = 1
      ),
      ":osxCase": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/**/*.h"
        ],
        exclude = [
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.hpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.hxx"
        ],
        exclude_directories = 1
      ),
      ":tvosCase": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/**/*.h"
        ],
        exclude = [
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.hpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.hxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/FBSDKHybridAppEventsScriptMessageHandler.h",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.hpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.hxx",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.hpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.hxx",
          "FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.h",
          "FBSDKCoreKit/FBSDKCoreKit/FBSDKMeasurementEvent.h",
          "FBSDKCoreKit/FBSDKCoreKit/FBSDKMutableCopying.h",
          "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.h",
          "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.h",
          "FBSDKCoreKit/FBSDKCoreKit/FBSDKURL.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.hpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.hxx",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAppLinkReturnToRefererView_Internal.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAppLink_Internal.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAudioResourceLoader.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKContainerViewController.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMeasurementEvent_Internal.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMonotonicTime.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKProfile+Internal.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKSystemAccountStoreAdapter.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKTriStateBOOL.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKURL_Internal.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKCloseIcon.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKColor.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKMaleSilhouetteIcon.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.hpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.hxx"
        ],
        exclude_directories = 1
      ),
      ":watchosCase": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/**/*.h"
        ],
        exclude = [
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.h",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.hpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/*.hxx"
        ],
        exclude_directories = 1
      )
    }
  ),
  visibility = [
    "//visibility:public"
  ]
)
filegroup(
  name = "Core_union_hdrs",
  srcs = [
    "Core_hdrs",
    "FBSDKCoreKit_hdrs"
  ],
  visibility = [
    "//visibility:public"
  ]
)
headermap(
  name = "Core_hmap",
  namespace = "FBSDKCoreKit",
  hdrs = [
    ":Core_union_hdrs"
  ],
  deps = [
    ":Basics"
  ],
  visibility = [
    "//visibility:public"
  ]
)
gen_includes(
  name = "Core_includes",
  include = [
    "Vendor/FBSDKCoreKit/pod_support/Headers/Public/"
  ]
)
objc_library(
  name = "Core",
  enable_modules = 0,
  srcs = select(
    {
      "//conditions:default": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
        ],
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
            ],
            exclude = [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*.m"
            ],
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":osxCase": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
        ],
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
            ],
            exclude = [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
            ],
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":tvosCase": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
        ],
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
            ],
            exclude = [
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/FBSDKHybridAppEventsScriptMessageHandler.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKMeasurementEvent.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.m",
              "FBSDKCoreKit/FBSDKCoreKit/FBSDKURL.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAudioResourceLoader.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKContainerViewController.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMonotonicTime.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKSystemAccountStoreAdapter.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKTriStateBOOL.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKCloseIcon.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKColor.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKMaleSilhouetteIcon.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.s"
            ],
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":watchosCase": glob(
        [
          "FBSDKCoreKit/FBSDKCoreKit/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
          "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
        ],
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
            ],
            exclude = [
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
            ],
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      )
    }
  ),
  non_arc_srcs = select(
    {
      "//conditions:default": glob(
        glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
          ],
          exclude = [
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.m",
            "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*.m"
          ],
          exclude_directories = 1
        ),
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
              ],
              exclude = [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceButton.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKDeviceViewControllerBase.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/Device/**/*.m"
              ],
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":osxCase": glob(
        glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
          ],
          exclude = [
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
          ],
          exclude_directories = 1
        ),
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
              ],
              exclude = [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
              ],
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":tvosCase": glob(
        glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
          ],
          exclude = [
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/FBSDKHybridAppEventsScriptMessageHandler.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.m",
            "FBSDKCoreKit/FBSDKCoreKit/FBSDKMeasurementEvent.m",
            "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.m",
            "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.m",
            "FBSDKCoreKit/FBSDKCoreKit/FBSDKURL.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAudioResourceLoader.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKContainerViewController.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMonotonicTime.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKSystemAccountStoreAdapter.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKTriStateBOOL.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKCloseIcon.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKColor.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKMaleSilhouetteIcon.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.s"
          ],
          exclude_directories = 1
        ),
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
              ],
              exclude = [
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/Codeless/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/AppEvents/Internal/FBSDKHybridAppEventsScriptMessageHandler.m",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKGraphErrorRecoveryProcessor.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKMeasurementEvent.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfile.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKProfilePictureView.m",
                "FBSDKCoreKit/FBSDKCoreKit/FBSDKURL.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/BridgeAPI/**/*.s",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKAudioResourceLoader.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKContainerViewController.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKMonotonicTime.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKSystemAccountStoreAdapter.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/FBSDKTriStateBOOL.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKCloseIcon.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKColor.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/UI/FBSDKMaleSilhouetteIcon.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Internal/WebDialog/**/*.s"
              ],
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      ),
      ":watchosCase": glob(
        glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
          ],
          exclude = [
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
          ],
          exclude_directories = 1
        ),
        exclude = glob(
          [
            "FBSDKCoreKit/FBSDKCoreKit/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
            "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
          ],
          exclude = glob(
            [
              "FBSDKCoreKit/FBSDKCoreKit/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppEvents/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/AppLink/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.s",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.S",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.c",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cc",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cpp",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.cxx",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.m",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.mm",
              "FBSDKCoreKit/FBSDKCoreKit/Internal/**/*.s"
            ],
            exclude = glob(
              [
                "FBSDKCoreKit/FBSDKCoreKit/**/*.m"
              ],
              exclude = [
                "FBSDKCoreKit/FBSDKCoreKit/Basics/**/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.S",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.c",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cc",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cpp",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.cxx",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.m",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.mm",
                "FBSDKCoreKit/FBSDKCoreKit/Basics/*.s"
              ],
              exclude_directories = 1
            ),
            exclude_directories = 1
          ),
          exclude_directories = 1
        ),
        exclude_directories = 1
      )
    }
  ),
  hdrs = [
    ":Core_union_hdrs"
  ],
  pch = pch_with_name_hint(
    "FBSDKCoreKit",
    glob(
      [
        "FBSDKCoreKit/**/*.pch"
      ],
      exclude_directories = 1
    )
  ),
  weak_sdk_frameworks = select(
    {
      "//conditions:default": [
        "Accounts",
        "CoreLocation",
        "Social",
        "Security",
        "QuartzCore",
        "CoreGraphics",
        "UIKit",
        "Foundation",
        "AudioToolbox"
      ],
      ":tvosCase": [
        "CoreLocation",
        "Security",
        "QuartzCore",
        "CoreGraphics",
        "UIKit",
        "Foundation",
        "AudioToolbox"
      ]
    }
  ),
  deps = [
    ":Basics",
    ":Core_includes"
  ],
  copts = select(
    {
      "//conditions:default": [
        "-DPOD_CONFIGURATION_RELEASE=0"
      ],
      ":release": [
        "-DPOD_CONFIGURATION_RELEASE=1",
        "-DNS_BLOCK_ASSERTIONS=1"
      ]
    }
  ) + [
    "-IVendor/FBSDKCoreKit/pod_support/Headers/Public/FBSDKCoreKit/"
  ] + [
    "-fmodule-name=FBSDKCoreKit_pod_module"
  ],
  data = [
    ":Core_Bundle_FacebookSDKStrings"
  ],
  visibility = [
    "//visibility:public"
  ]
)
acknowledged_target(
  name = "Core_acknowledgement",
  deps = [],
  value = "//Vendor/FBSDKCoreKit/pod_support_buildable:acknowledgement_fragment"
)
