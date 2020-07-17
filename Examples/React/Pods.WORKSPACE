new_pod_repository(
  name = "Folly",
  url = "https://github.com/facebook/folly/archive/v2016.09.26.00.zip",
  podspec_url = "Vendor/React/third-party-podspecs/Folly.podspec",

  # This setting is set in folly, but we ignore it
  generate_header_map = False,
)

new_pod_repository(
  name = "DoubleConversion",
  url = 'https://github.com/google/double-conversion/archive/v1.1.6.zip',
  podspec_url = 'Vendor/React/third-party-podspecs/DoubleConversion.podspec',
  install_script = """
    # prepare_command
    mv src double-conversion
    __INIT_REPO__
  """,
  generate_module_map = False
)

# podfile_deps.py picks up the workspace generated from cocoapods
load("podfile_deps.py")
