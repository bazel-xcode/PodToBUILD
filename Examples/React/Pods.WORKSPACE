new_pod_repository(
  name = "boost-for-react-native",
  url = 'https://github.com/react-native-community/boost-for-react-native/archive/v1.63.0-0.zip',
  # This podspec isn't included in the http archives of boost.
  podspec_url = 'Vendor/PodSpecs/boost-for-react-native-1.63.0-0/boost-for-react-native.podspec',
  generate_module_map = False,
  install_script = """
    __INIT_REPO__
    # This isn't actually necessary but nice.
    rm -rf pod_support/Headers/Public/*
  """,
)

# Prior hacks for podspecs
# - Copy over third-party-podspecs to Vendor/Podspecs
# - Comment out busted prepare commands

# Apply this patch for headermaps to work.
# Will fix in a followup
"""
$ diff -Naru Vendor/React/BUILD /tmp/React.base.BUILD
--- Vendor/React/BUILD  2019-10-01 12:47:05.000000000 -0700
+++ /tmp/React.base.BUILD       2019-10-01 12:45:04.000000000 -0700
@@ -3057,9 +3057,7 @@
   name = "RCTBlob_cxx_hmap",
   namespace = "React",
   hdrs = [
-    ":RCTBlob_cxx_union_hdrs",
-    ":RCTNetwork_union_hdrs",
-    ":RCTWebSocket_union_hdrs"
+    ":RCTBlob_cxx_union_hdrs"
   ],
   hdr_providers = [
     ":Core"
"""

new_pod_repository(
  name = "React",
  owner = "@ios-cx",
  url = 'https://github.com/facebook/react-native/archive/v0.59.10.zip',
  user_options = [
    # TODO: If Xcode is compiling CppLike with this standard, P2B should too.
    "CxxBridge_cxx.copts += -std=c++14",
    "cxxreact.copts += -std=c++14",
    "jsinspector.copts += -std=c++14",
    "jsiexecutor.copts += -std=c++14",
    "jsi.copts += -std=c++14",
    "Core_cxx.deps += //Vendor/Folly:Folly",
  ],

  # Module map doesn't work because it seems to be expecting the folly library
  generate_module_map = False,
  inhibit_warnings = True,
  generate_header_map = True
)

new_pod_repository(
  name = "Folly",
  owner = "@ios-cx",
  podspec_url = "Vendor/PodSpecs/react-0.59/third-party-podspecs/Folly.podspec",
  url = 'https://github.com/facebook/folly/archive/v2018.10.22.00.zip',
  install_script = """
    # Force folly demangler off, we don't need it and it's being incorrectly enabled causing compile errors.
    /usr/bin/sed -i '' 's/FOLLY_DETAIL_HAVE_DEMANGLE_H 1/FOLLY_DETAIL_HAVE_DEMANGLE_H 0 \/\/ PINTEREST HACK, SEE Pods.WORKSPACE/g' folly/detail/Demangle.h
    # Rename 'build' directory temporarily as its name conflicts with bazel generated BUILD file.
    # Better future solution is to update P2B to export BUILD.bazel files.
    mv build build.orig
    __INIT_REPO__
    mv BUILD BUILD.bazel
    mv build.orig build
  """,
  generate_module_map = False
)

new_pod_repository(
  name = "DoubleConversion",
  url = 'https://github.com/google/double-conversion/archive/v1.1.6.zip',
  podspec_url = 'Vendor/PodSpecs/react-0.59/third-party-podspecs/DoubleConversion.podspec',
  install_script = """
    # prepare_command
    mv src double-conversion
    __INIT_REPO__
  """,
  generate_module_map = False
)

new_pod_repository(
  name = "glog",
  url = 'https://github.com/google/glog/archive/v0.3.5.zip',
  podspec_url = 'Vendor/PodSpecs/react-0.59/third-party-podspecs/glog.podspec',
  install_script = """
    # prepare_command
  	sh ../PodSpecs/glog-0.3.5/ios-configure-glog.sh
  	__INIT_REPO__
  """,
  generate_module_map = False,
  # See above patch
  # generate_header_map = True
)


# WARNING: the version of react-native here doesn't match up with yoga.
new_pod_repository(
  name = "yoga",
  owner = "@ios-cx",
  url = 'https://github.com/facebook/react-native/archive/v0.55.4.zip',
  strip_prefix = 'react-native-0.55.4/ReactCommon/yoga',
  install_script = """
    # We need to fix the package parameter here (even though we don't use in pod2build)
    # because the evaluation of the podspec in Ruby will fail. The package parameter
    # points to a JSON.parse of a file outside the yoga sandbox.
    /usr/bin/sed -i "" "s,^package.*,package = { 'version' => '0.46.3' },g" Yoga.podspec
    __INIT_REPO__
  """,
  generate_module_map = False,
  generate_header_map = True
)

