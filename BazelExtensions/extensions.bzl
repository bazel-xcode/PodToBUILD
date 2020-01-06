# This file is part of PodSpecToBUILD
# Warning: this file is not accounted for as an explict imput into the build.
# Therefore, bin/RepoTools must be updated when this changes.

# Acknowledgements

AcknowledgementProvider = provider()

def _acknowledgement_merger_impl(ctx):
    concat = list(ctx.attr.value.files) if ctx.attr.value else []
    action = "--merge" if ctx.attr.value else "--finalize"
    args = [action, ctx.outputs.out.path]

    # Merge all of the dep licenses
    for dep in ctx.attr.deps:
        license = dep.files.to_list()
        concat.extend(license)

    for f in concat:
        args.append(f.path)

    # Write the final output. Bazel only writes the file when required
    ctx.actions.run(
        inputs=concat,
        arguments=args,
        executable=ctx.attr.merger.files.to_list()[0],
        outputs=[ctx.outputs.out]
    )

    return [AcknowledgementProvider(value=concat)]


acknowledgement_merger = rule(
    implementation=_acknowledgement_merger_impl,
    attrs={
        # We expect the deps to be AcknowledgementProviders
        # It isn't possible to enforce this across external package boundaries,
        "deps": attr.label_list(allow_files=True),
        "value": attr.label(),
        "output_name": attr.string(),
        "merger": attr.label(
            executable=True,
            cfg="host"
        )
    },
    outputs={"out": "%{output_name}.plist"}
)

# acknowledgments plist generates Acknowledgements.plist for use in a
# Settings.bundle


def acknowledgments_plist(name,
                          deps,
                          output_name="Acknowledgements",
                          merger="//Vendor/rules_pods/BazelExtensions:acknowledgement_merger",
                          ):
    acknowledgement_merger(
        name=name,
        deps=deps,
        value=None,
        output_name=output_name,
        merger=merger,
        visibility=["//visibility:public"]
    )

# acknowledged target takes a value in the form of a license file
#
# It may depend on other acknowledged targets


def acknowledged_target(name,
                        deps,
                        value,
                        merger="//Vendor/rules_pods/BazelExtensions:acknowledgement_merger",
                        ):
    acknowledgement_merger(
        name=name,
        deps=deps,
        output_name=name + "-acknowledgement",
        value=value,
        merger=merger,
        visibility=["//visibility:public"]
    )

# pch_with_name_hint
#
#   Take in a name hint and return the PCH with that name
#
# Parameters
#
#   hint - Suggestion of pch file name. If any part of this is in a PCH
#   filename it will match
#
#   sources - a list of source file patterns with pch extensions to search


def pch_with_name_hint(hint, sources):
    # Recursive glob the sources directories and the root directory
    candidates = native.glob(["*.pch", hint + "/*.pch"] + sources)
    if len(candidates) == 0:
        return None

    # We want to get the candidates in order of lowest to highest
    for candidate in candidates:
        if hint in candidate:
            return candidate
    # It is a convention in iOS/OSX development to use a PCH
    # with the name of the target.
    # This is a hack because, the recursive glob may find some
    # arbitrary PCH.
    return None


def _make_module_map(pod_name, module_name, deps, is_system):
    # Up some dirs to the compilation root
    # bazel-out/ios_x86_64-fastbuild/genfiles/external/__Pod__
    relative_path = "../../../../../../"

    system_tag = " [system] "
    template = "module " + module_name + (system_tag if is_system else "" ) + " {\n"
    template += "    export * \n"
    for provider in deps:
        for input_file in provider.files.to_list():
            if input_file.path.endswith(".hmap"):
                continue
            hdr = input_file
            template += "    header \"%s%s\"\n" % (relative_path, hdr.path)
    template += "}\n"
    return template

def _gen_module_map_impl(ctx):
  out = _make_module_map(ctx.attr.pod_name, ctx.attr.module_name, ctx.attr.hdrs, ctx.attr.is_system)
  ctx.actions.write(
      content=out,
      output=ctx.outputs.module_map
  )
  objc_provider = apple_common.new_objc_provider(
      module_map=depset([ctx.outputs.module_map])
  )
  return struct(
     files=depset([ctx.outputs.module_map]),
     providers=[objc_provider],
     objc=objc_provider,
     headers=depset([ctx.outputs.module_map]),
  )

_gen_module_map = rule(
    implementation=_gen_module_map_impl,
    output_to_genfiles=True,
    attrs = {
        "pod_name": attr.string(mandatory=True),
        "hdrs": attr.label_list(mandatory=True),
        "module_name": attr.string(mandatory=True),
        "dir_name": attr.string(mandatory=True),
        "module_map_name": attr.string(mandatory=True),
        "is_system": attr.bool(mandatory=True),
    },
    outputs = { "module_map": "%{dir_name}/%{module_map_name}" }
)

def gen_module_map(pod_name,
                   dir_name,
                   module_name,
                   dep_hdrs=[],
                   module_map_name="module.modulemap",
                   tags=["xchammer"],
                   is_system=True,
                   visibility=["//visibility:public"]):
    """
    Generate a module map based on a list of header file groups

    pod_name: the name of the pod
    dir_name: the name of the output directory, this is generally included by the compiler
    module_name: the name of the module
    is_system: if the module is system module or not. This is useful for
               PodToBUILD to ignore all pod warnings by default
    """
    # TODO:Modules change the name to dir_name -> pod_name
    # It's also kind of weird that the rule name is changed inside of here.
    _gen_module_map(name = dir_name + "_module_map_file",
                    pod_name=pod_name,
                    dir_name=dir_name,
                    module_name=module_name,
                    hdrs=dep_hdrs,
                    module_map_name=module_map_name,
                    is_system=is_system,
                    visibility=visibility,
                    tags=tags)

def _gen_includes_impl(ctx):
    includes = []
    includes.extend(ctx.attr.include)
    for target in ctx.attr.include_files:
        for f in target.files.to_list():
            includes.append(f.path)

    return apple_common.new_objc_provider(
            include=depset(includes))

_gen_includes = rule(
    implementation=_gen_includes_impl,
    attrs = {
        "include": attr.string_list(mandatory=True),
        "include_files": attr.label_list(mandatory=True),
    }
)

def gen_includes(name,
                 include=[],
                 include_files=[],
                 tags=["xchammer"],
                 visibility=["//visibility:public"]):
    _gen_includes(name=name,
                  include=include,
                  include_files=include_files,
                  tags=tags,
                  visibility=visibility)


def _make_headermap_json(namespace, hdrs):
    mappings = {}
    for provider in hdrs:
        for input_file in provider.files.to_list():
            hdr = input_file
            namespaced_key = namespace + "/" + hdr.basename
            mappings[namespaced_key] = hdr.path
            mappings[hdr.basename] = hdr.path
    return struct(mappings=mappings).to_json()


def _make_headermap_impl(ctx):
    # Write a JSON file for *this* headermap
    json_f = ctx.actions.declare_file(ctx.label.name + "_internal.json")
    out = _make_headermap_json(ctx.attr.namespace, ctx.attr.hdrs)
    ctx.actions.write(
        content=out,
        output=json_f
    )

    # Add a list of headermaps in JSON or hmap format
    args = [ctx.outputs.headermap.path, json_f.path]
    inputs = [json_f]

    # Extract propagated headermaps
    for hdr_provider in ctx.attr.deps:
        if not hasattr(hdr_provider, "objc"):
            continue

        hdrs = hdr_provider.objc.header.to_list()
        for hdr in hdrs:
            if hdr.path.endswith(".hmap"):
                # Add headermaps
                inputs.append(hdr)
                args.append(hdr.path)

    ctx.actions.run(
        inputs=inputs,
        arguments=args,
        executable=ctx.attr.headermap_builder.files.to_list()[0],
        outputs=[ctx.outputs.headermap]
    )

    objc_provider = apple_common.new_objc_provider(
        header=depset([ctx.outputs.headermap]),
    )
    return struct(
        files=depset([ctx.outputs.headermap]),
        providers=[objc_provider],
        objc=objc_provider,
        headers=depset([ctx.outputs.headermap]),
    )

def headermap(
    tags=["xchammer"],**kwargs):
    _headermap(tags=tags, **kwargs)

# Derive a headermap from transitive headermaps
# hdrs: a file group containing headers for this rule
# namespace: the Apple style namespace these header should be under
# deps: rules providing headers. i.e. an `objc_library`
# Note: this intententionally does not propgate the include. We don't want to
# end up with O(N) includes.
# The pattern in PodToBUILD is:
# - Add all deps to a headermap
# - Include the headermap
# TODO(Add the ability to disallow propagation of "internal" includes )
# e.g. "MyLib.h" instead of <MyLib/MyLib.h>
_headermap = rule(
    implementation=_make_headermap_impl,
    output_to_genfiles=True,
    attrs={
        "namespace": attr.string(mandatory=True),
        "hdrs": attr.label_list(mandatory=True),
        "deps": attr.label_list(mandatory=False),
        "headermap_builder": attr.label(
            executable=True,
            cfg="host",
            default=Label(
                "//Vendor/rules_pods/BazelExtensions:headermap_builder"),
        )
    },
    outputs={"headermap": "%{name}.hmap"}
)

