new_pod_repository(
  name = "boost-for-react-native",
  url = 'https://github.com/react-native-community/boost-for-react-native/archive/v1.63.0-0.zip',
  # This podspec isn't included in the http archives of boost.
  podspec_url = 'Vendor/PodSpecs/boost-for-react-native-1.63.0-0/boost-for-react-native.podspec',
  generate_module_map = False,
  install_script = """
    __INIT_REPO__
    # TODO: We need to add the ability to not generate this dir.
    rm -rf pod_support/Headers/Public/boost
  """,
)

new_pod_repository(
  name = "Folly",
  podspec_url = "Vendor/PodSpecs/react-0.57/third-party-podspecs/Folly.podspec",
  url = "https://github.com/facebook/folly/archive/v2016.09.26.00.zip",
  generate_module_map = False
)

new_pod_repository(
  name = "DoubleConversion",
  url = 'https://github.com/google/double-conversion/archive/v1.1.5.zip',
  podspec_url = 'Vendor/PodSpecs/react-0.57/third-party-podspecs/DoubleConversion.podspec',
  install_script = """
    # prepare_command
    mv src double-conversion
    __INIT_REPO__
  """,

  generate_module_map = False
)

new_pod_repository(
  name = "glog",
  url = 'https://github.com/google/glog/archive/v0.3.4.zip',
  podspec_url = 'Vendor/PodSpecs/react-0.57/third-party-podspecs/GLog.podspec',
  install_script = """
    # prepare_command
  	sh ../PodSpecs/glog-0.3.4/ios-configure-glog.sh || exit 1
  	__INIT_REPO__
  """,
  generate_module_map = False
)

# Prior, required manual changes
# - Copy over third-party-podspecs to Vendor/Podspecs
# - Comment out busted prepare commands
new_pod_repository(
  name = "React",
  url = 'https://github.com/facebook/react-native/archive/v0.57.0.zip',
  user_options = [
    # TODO: https://github.com/pinterest/PodToBUILD/issues/51
    "jsinspector.copts += -std=c++14",
  ],

  # Module map doesn't work because it seems to be expecting the folly library
  generate_module_map = False,
  inhibit_warnings = True,
)

new_pod_repository(
  name = "yoga",
  url = 'https://github.com/facebook/react-native/archive/v0.55.4.zip',
  strip_prefix = 'react-native-0.55.4/ReactCommon/yoga',
  install_script = """
    # We need to fix the package parameter here (even though we don't use in pod2build)
    # because the evaluation of the podspec in Ruby will fail. The package parameter
    # points to a JSON.parse of a file outside the yoga sandbox.
    /usr/bin/sed -i "" "s,^package.*,package = { 'version' => '0.46.3' },g" Yoga.podspec
  	__INIT_REPO__
  """,

  generate_module_map = False
)
