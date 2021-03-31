new_pod_repository(
  name = "Folly",
  url = "https://github.com/facebook/folly/archive/v2020.01.13.00.zip",
  podspec_url = "Vendor/React/third-party-podspecs/Folly.podspec",

  install_script = """
    __INIT_REPO__
    # This isn't actually necessary but nice.
    rm -rf pod_support/Headers/Public/*

    # __has_include erroneously returns true for damangle.h, which later causes an link error
    sed -i '' 's/__has_include(<demangle.h>)/false/g' folly/detail/Demangle.h
  """,
  generate_header_map = False
)
new_pod_repository(
  name = "DoubleConversion",
  url = 'https://github.com/google/double-conversion/archive/v1.1.6.zip',
  podspec_url = 'Vendor/React/third-party-podspecs/DoubleConversion.podspec',
  install_script = """
    # prepare_command
    mv src double-conversion
    __INIT_REPO__
  """
)

new_pod_repository(
  name = "glog",
  url = 'https://github.com/google/glog/archive/v0.3.5.zip',
  podspec_url = 'Vendor/React/third-party-podspecs/glog.podspec',
  install_script = """
    # prepare_command
    sh ../React/scripts/ios-configure-glog.sh
    __INIT_REPO__
  """
)

new_pod_repository(
  name = "boost-for-react-native",
  url = "https://github.com/react-native-community/boost-for-react-native/archive/v1.63.0-0.zip",
  podspec_url = "Vendor/Podspecs/boost-for-react-native.podspec.json",
  generate_header_map = False,
  install_script = """
    __INIT_REPO__
    # This isn't actually necessary but nice.
    rm -rf pod_support/Headers/Public/*
  """,
)

# podfile_deps.py picks up the workspace generated from cocoapods
load("podfile_deps.py")
