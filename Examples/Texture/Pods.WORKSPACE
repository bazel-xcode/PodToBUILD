new_pod_repository(
  name = "Texture",
  url = "https://github.com/TextureGroup/Texture/archive/d085cd63494488c5921e20842a585470aa6ab1d9.zip",
  inhibit_warnings = True,
  # Undefined symbols
  # Compilation error: triggered module compilation from ObjC code
  generate_module_map = False,
)


new_pod_repository(
  name = "PINRemoteImage",
  url = "https://github.com/pinterest/PINRemoteImage/archive/a06b4746ebbe45c87c2b449e8a40a6b7ddf96051.zip",
  # PINRemoteImage_Core conditionally compiles in PINCache based on these
  # headers
  user_options = ["Core.deps += //Vendor/PINCache:PINCache"],

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

