An easy way to integrate `CocoaPods.org` into Bazel.

`PodSpecToBUILD` integrates Pod dependencies end to end with an easy to use
macro.


### Quickstart Instructions:

In your `WORKSPACE` file, setup the `rules_pods` repository.

```
# Initialize the `rules_pods` repository
new_http_archive(
  name = "rules_pods",
  #TODO:OSS actual URL
  remote = "http//:github.com/Pinterest/rules_pods/releases/archive/0.1.zip",
  visibility = ["//visibility:public"]
)

load('@rules_pods//BazelExtensions:workspace.bzl', 'new_pod_repository')
```
<br />

### Adding Pods

That's it. Now you're ready to add Pods.

Repositories are initialized in the `WORKSPACE` file with the macro,
`new_pod_repository`.

<br />
```
new_pod_repository(
  name = "PINOperation",
  url = "https://github.com/pinterest/PINOperation/archive/1.0.3.zip",
)
```
<br />

The package `@PINOperation` and the associated `objc_library` target,
`PINOperation`, is available for use within Bazel. The package and target name
are combined to form the label `@PINOperation//:PINOperation`.

## new_pod_repository

This macro is the main point of integration for pod dependencies.

Each pod is integrated as a repository and each repository is self contained.

By declaring a `new_pod_repository` in the `WORKSPACE` file, the dependency is
automatically availble within all Bazel targets.

### Naming Convention

In Bazel a label is a build target identifier. Pod labels are all formed using
the same logic.

The first part of the label is the package name, followed by the name of the
target: `@__PACKAGE__//:__TARGET__`

The top level target is determined by the root subspec.

For example, in `PINCache`, the root target's label is `@PINCache//:PINCache`.

Subspecs targets have the same name as the subspec. For example, the label of the
subpsec `Core` in `PINCache` is `@PINCache//:Core`

### Dependencies on Pods

As with any external dependencies in Bazel, all transitive dependencies must be
declared in the `WORKSPACE`.

Dependencies between targets are resolved through an idiomatic naming
convention.

For example, `PINCache` depends on `PINOperation`. In `PINCache`'s `BUILD` file,
the dependency on `@PINOperation//:PINOperation` is generated.  The `WORKSPACE`
needs to declare both `PINOperation` and `PINCache`.

### Local Dependencies

Local dependencies in `new_pod_repository` are supported in addition to remote
ones.

Instead of using a `url` that points to the remote repository, use a `url` that
points to the local repository.

For example, if we wanted to depend on a local version of `PINOperation`: 
```
new_pod_repository(
  name = "PINOperation",
  url = "/Path/To/PINOperation",
)
```

Upon building, the local files are linked into the pod directory.

This can aid in local development of external dependencies, and was originally
designed for such a use case.

### Resolving issues with dependencies

Many dependencies will work with `new_pod_repository` without any special
considerations: just add the `name`, and `url`.

Some dependencies may not. The `install_script` attribute is a way to resolve
issues with such dependencies.

For example, in `PINRemoteImage` source files are in folders that have spaces in
the name. This is not supported in Bazel. Please see the [Known
incompatibilities section]() for more info.

### Customizing rule attributes

It may be desirable or required to change the way that a target is built. The
compiler supports customizing attributes of generated targets.

For example, to add a custom `copt` to `PINOperation` we could turn on pedantic
warnings just for `PINOperation//:PINOperation`

```
new_pod_repository(
  name = "PINOperation",
  url = "https://github.com/pinterest/PINOperation/archive/1.0.3.zip",
  user_options = ["PINOperation.copts += -pedantic"],
)
```

On `objc_library`, the following fields are supported: `copts`, `deps`,
`sdkFrameworks`

### Acknowledgements Plist and Settings.bundle

Acknowledgments metadata from a Pod is supported.

A target containing acknowledgment metadata for a given target is automatically
generated. Acknowledgment targets have the label of the form
`@__PACKAGE__//:$__POD_NAME___acknowledgment`

Merge all of the dependencies into your `Settings.bundle`

```
load("@rules_pods//BazelExtensions:extensions.bzl", "acknowledgments_plist")

# Example `Settings`.bundle target
objc_bundle_library(
    name = "Settings",
    resources = ["Root.plist", "acknowledgements"],
    visibility = ['//visibility:public'],
)

ALL_POD_DEPS = ["@PINOperation//:PINOperation", "@PINCache//:PINCache"]
acknowledgments_plist(
    name = "acknowledgements",
    deps = [d + "_acknowledgement" for d in ALL_POD_DEPS],
    merger = "@rules_pods//BazelExtensions:acknowledgement_merger"
)
```

### `new_pod_repository` Attribute reference

`name`: the name of this repo

`url`: the url of this repo

`podspec_url`: the podspec url. By default, we will look in the root of the
repository, and read a .podspec file. This requires having CocoaPods installed
on build nodes. If a JSON podspec is provided here, then it is not required to
run CocoaPods.

`owner`: the owner of this dependency #TODO:OSS remove owner

`strip_prefix`: a directory prefix to strip from the extracted files.  Many
archives contain a top-level directory that contains all of the useful files in
archive.

For most sources, this is typically not needed.

`user_options`: an array of key value operators that act on code
generated `target`s.

Supported operators:
PlusEquals ( += ). Add an item to an array

Implemented for:
`objc_library`. Supported fields: `copts`, `deps`, `sdkFrameworks`

Example usage: add a custom define to the target, Texture's `copts`
field

```
user_options = [ "Texture.copts += -DTEXTURE_DEBUG " ]
```

`install_script`: a script used for installation.

The placeholder `__INIT_REPO__` indicates at which point the BUILD file is
generated, if any.

`repo_tools` may be provided as a label. The names provided in `repo_tools` are
substituted out for the respective tools.

note that the script is ran directly after the repository has been fetched.

`repo_tools`: a mapping of executables in Bazel to command names.  If we are
running something like "mv" or "sed" these binaries are already on path, so
there is no need to add an entry for them.

`inhibit_warnings`: whether compiler warnings should be inhibited.

`trace`: dump out useful debug info for a given repo.

`generate_module_map`: whether a module map should be generated.

`enable_modules`: set generated rules `enable_modules` parameter

`header_visibility`: DEPRECATED: This is replaced by headermaps: https://github.com/Bazelbuild/Bazel/pull/3712

### Known Complications

### Incompatible file paths

Apple File systems support different characters than Linux ones do. Bazel uses
the least common denominator, the Linux convention. For now, use an
`install_script` to resolve differences.

### __has_include directive

Some code, like `Texture` uses `__has_include` to conditionally include code.

In Bazel, if that include is not explicitly added, then this feature will not
work. In this case, use a `user_option` to add dependencies available on your
system.

### Incompatible Target Names

Some targets may contain characters that are not valid Bazel targets.

The target should be renamed to a compatible name. The easiest way to achieve
this is to declare the dependency with a valid name. All references should be
replaced in the podspec file before the `BUILD` file is generated.

For example `SPUserResizableView+Pion` exbibits this issue.

```
new_pod_repository(
    name = "SPUserResizableView_Pion",
    url = "https://github.com/keleixu/SPUserResizableView/archive/b263fc4e8101c6c5ac352806fb5c31aa69e32025.zip",
    user_options = ["SPUserResizableView_Pion.sdk_frameworks += UIKit, CoreGraphics, Foundation"],
    inhibit_warnings = True,
    install_script = """
        /usr/bin/sed -i "" 's,SPUserResizableView+Pion,SPUserResizableView_Pion,g' 'SPUserResizableView+Pion.podspec'
        mv 'SPUserResizableView+Pion.podspec' 'SPUserResizableView_Pion.podspec'
        __INIT_REPO__
    """,

    generate_module_map = False
)
```

Now, in Bazel, the target is accessible via `SPUserResizableView_Pion` instead
of `SPUserResizableView_Pion`.

This should eventually be handled by default.


