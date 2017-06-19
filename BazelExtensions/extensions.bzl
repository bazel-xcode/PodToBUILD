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
    ctx.action(
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
                          merger="//pod_support_buildable:acknowledgement_merger",
                          ):
    acknowledgement_merger(
        name=name,
        deps=deps,
        value=None,
        output_name="Acknowledgements",
        merger=merger,
        visibility=["//visibility:public"]
    )

# acknowledged target takes a value in the form of a license file
#
# It may depend on other acknowledged targets


def acknowledged_target(name,
                        deps,
                        merger="//pod_support_buildable:acknowledgement_merger",
                        value="//pod_support_buildable:acknowledgement_fragment",
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
