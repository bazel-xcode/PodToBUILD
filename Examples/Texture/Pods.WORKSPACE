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
  url = "https://github.com/pinterest/PINRemoteImage/archive/3.0.3.zip",
  # PINRemoteImage_Core conditionally compiles in PINCache based on these
  # headers
  user_options = ["Core.deps += //Vendor/PINCache:PINCache"],

  generate_module_map = False,
  generate_header_map = True,
)

new_pod_repository(
  name = "PINOperation",
  url = "https://github.com/pinterest/PINOperation/archive/1.2.1.zip",
  generate_header_map = True
)

new_pod_repository(
  name = "PINCache",
  url = "https://github.com/pinterest/PINCache/archive/3.0.3.zip",
  generate_header_map = True
)
