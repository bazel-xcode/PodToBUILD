new_pod_repository(
  name = "PINRemoteImage",
  url = "https://github.com/pinterest/PINRemoteImage/archive/a06b4746ebbe45c87c2b449e8a40a6b7ddf96051.zip",
  # PINRemoteImage_Core conditionally compiles in PINCache based on these
  # headers
  user_options = ["Core.deps += //Vendor/PINCache:PINCache"],

  # TODO:
  generate_module_map = False
)

new_pod_repository(
  name = "PINOperation",
  url = "https://github.com/pinterest/PINOperation/archive/1.1.zip"
)

new_pod_repository(
  name = "PINCache",
  url = "https://github.com/pinterest/PINCache/archive/d886490de6d297e38f80bb750ff2dec4822fb870.zip"
)

