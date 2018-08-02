new_pod_repository(
  name = "React",
  url = 'https://github.com/facebook/react-native/archive/v0.51.0.zip',
  # In the React podspec, C++14 is specified as the std lib. In Xcode, this
  # is fine as this flag is only used on C++ files. But in Bazel, it is used
  # on all files. This breaks builds for objective-c and C code.
  #
  # We can't just treat all files as objective-c++ either because some of the
  # files have code that is valid C but invalid C++. Luckily, the set of
  # libraries that are invalid C++ are disjoint from the ones that contain C++
  # so we're able to get this working by treating some as gnu99 and others
  # as just objective-c++ files.
  user_options = [
    "RCTImage.copts += -std=gnu99",
    "DevSupport.copts += -x, objective-c++",
    "RCTNetwork.copts += -x, objective-c++",
    "RCTText.copts += -std=gnu99",
    "RCTWebSocket.copts += -std=gnu99",
    "RCTAnimation.copts += -x, objective-c++",
    "RCTBlob.copts += -x, objective-c++",
    "fishhook.copts += -std=gnu99",
    # FIXME: the way that these headers are being imported is causing massive
    # issues. We need to run in sandbox'd mode to get around this.
    "cxxreact.copts += -IVendor/boost",
    "jschelpers.copts += -IVendor/boost, -IVendor/DoubleConversion, -IVendor/Folly",
    "CxxBridge.copts += -IVendor/boost, -IVendor/DoubleConversion, -IVendor/Folly"
  ],
  install_script = """
    # Make sure we refer to yoga as Yoga since case-sensitivity matters in Bazel

    echo $PWD
    /usr/bin/sed -i "" 's,"yoga","Yoga",g' React.podspec
    __INIT_REPO__

    # TODO: Make variable replacement
    /usr/bin/sed -i '' 's,$(PODS_ROOT),Vendor,g' BUILD
    /usr/bin/sed -i '' 's,Folly:Folly,Folly:folly,g' BUILD
  """,
  # Module map doesn't work because it seems to be expecting the folly library
  generate_module_map = False,
  header_visibility = "everything",
  inhibit_warnings = True
)

new_pod_repository(
  name = "Yoga",
  url = 'https://github.com/facebook/react-native/archive/v0.51.0.zip',
  strip_prefix = 'react-native-0.51.0/ReactCommon/yoga',
  install_script = """
    mv yoga.podspec Yoga.podspec.bak
    mv Yoga.podspec.bak Yoga.podspec

    # We need to fix the package parameter here (even though we don't use in pod2build)
    # because the evaluation of the podspec in Ruby will fail. The package parameter
    # points to a JSON.parse of a file outside the yoga sandbox.
    /usr/bin/sed -i "" "s,^package.*,package = { 'version' => '0.46.3' },g" Yoga.podspec
    /usr/bin/sed -i "" "s,spec.module_name.*yoga,spec.module_name = 'Yoga,g" Yoga.podspec
    __INIT_REPO__
  """,

  generate_module_map = False
)

new_pod_repository(
  name = "boost",
  url = 'https://github.com/react-native-community/boost-for-react-native/archive/v1.63.0-0.zip',
  podspec_url = 'Vendor/PodSpecs/boost-react-native-1.63.0-0/boost.podspec.json',
  generate_module_map = False,
  install_script = """
    __INIT_REPO__
    patch BUILD < ../../Boost.patch
  """
)

new_pod_repository(
  name = "Folly",
  podspec_url = "Vendor/PodSpecs/react-native-third-party-0.51.0/Folly.podspec",
  url = "https://github.com/facebook/folly/archive/v2016.09.26.00.zip",
  generate_module_map = False,
  user_options = [ "folly.copts += -IVendor/Glog" ],
  install_script = """
    __INIT_REPO__
    # TODO: Why is the Podspec using this as a ModuleName, if Folly imports
    # it like so.
    /usr/bin/sed -i '' 's,<double-conversion,<DoubleConversion,g' folly/Conv.h

    # TODO: Make variable replacement
    /usr/bin/sed -i '' 's,$(PODS_ROOT),Vendor,g' BUILD

    patch BUILD < ../../Folly.patch
  """,
  header_visibility = 'everything',
)

new_pod_repository(
  name = "DoubleConversion",
  url = 'https://github.com/google/double-conversion/archive/v1.1.5.zip',
  podspec_url = 'Vendor/PodSpecs/react-native-third-party-0.51.0/DoubleConversion.podspec',
  install_script = """
    mv src double-conversion
    __INIT_REPO__
  """,

  generate_module_map = False
)

new_pod_repository(
  name = "Glog",
  url = 'https://github.com/google/glog/archive/v0.3.4.zip',
  podspec_url = 'Vendor/PodSpecs/react-native-third-party-0.51.0/GLog.podspec',
  install_script = """
    # prepare_command
  	sh ../PodSpecs/react-native-third-party-0.51.0/ios-configure-glog.sh
  	__INIT_REPO__
  """,
  generate_module_map = False
)

# TODO: The fact that this name is "DoubleConversion" is not very idomatic
# and causes issues.
new_pod_repository(
  name = "DoubleConversion",
  url = 'https://github.com/google/double-conversion/archive/v1.1.5.zip',
  podspec_url = 'Vendor/PodSpecs/react-native-third-party-0.51.0/DoubleConversion.podspec',
  install_script = """
    # prepare_command
    mv src double-conversion
    __INIT_REPO__
  """,
  generate_module_map = False
)

