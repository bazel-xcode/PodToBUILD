# PodToBUILD

An easy way to build CocoaPods with Bazel - it integrates pods end to end with
an easy to use macro.

[![Build Status](https://travis-ci.org/pinterest/PodToBUILD.svg?branch=master)](https://travis-ci.org/pinterest/PodToBUILD)

### Quickstart Instructions:

In the root directory, add `rules_pods` to the Bazel `WORKSPACE`.

```
http_archive(
    name = "rules_pods",
    urls = ["https://github.com/pinterest/PodToBUILD/releases/download/0.25.2-fc71a0b/PodToBUILD.zip"],
)
```

### Adding Pods

Pods are defined in the `WORKSPACE` file with the macro, `new_pod_repository`.

```
# Load the new_pod_repository macro - needed for `WORKSPACE` usage
load("@rules_pods//BazelExtensions:workspace.bzl", "new_pod_repository")

new_pod_repository(
  name = "PINOperation",
  url = "https://github.com/pinterest/PINOperation/archive/1.0.3.zip",
)
```

The package `PINOperation` and the associated `objc_library` target,
`PINOperation`, is available for use within Bazel. The package and target name
are combined to form the label `@PINOperation//:PINOperation`.

Thats all! Bazel will automatically setup pods along with the build.

_See the [examples](https://github.com/pinterest/PodToBUILD/tree/master/Examples) for end to end usage_.

### Vendoring Pods via Pods.WORKSPACE

By default, `rules_pods` supports Bazel's [conventional dependency management
system](https://docs.bazel.build/versions/master/external.html) via the
`WORKSPACE` / `new_pod_repository` macro.

However, loading external files as part of the build may have implications on
stability, Xcode usage, network bandwidth, and build times. e.g. downloading
dependencies from an external service ties build time and reliability to that
service.

As a solution, it supports `vendoring` aka out of band, in tree dependency
installation. Similar to `CocoaPods`, it can download and initialize Pods
relative to the project, in the `Vendor` directory. 

The program, `bin/update_pods`, installs Pods into `Vendor/__POD_NAME__`.  This
notion is similar to `pod install`.

_Usage:_

Create the file `Pods.WORKSPACE` and add `new_pod_repository`s' there -
`rules_pods`'s `http_archive` remains declared in the `WORKSPACE`.

Anytime `Pods.WORKSPACE` is changed, `update_pods` must be ran to ensure all
pods are updated.

```
# src_root is the root workspace directory
bazel run @rules_pods//:update_pods -- --src_root $PWD
```

In addition to out of band updating, labels are formed via the convention
`//Vendor:__POD_NAME__:__TARGET__`. Otherwise, the API of `new_pods_repository`
is identical across `WORKSPACE` and `Pods.WORKSPACE`, the only difference is
that the `load` statement isn't required in `Pods.WORKSPACE`.

_See the
[Texture](https://github.com/pinterest/PodToBUILD/tree/master/Examples/Texture)
example for a comprehensive example._

## new_pod_repository

This macro is the main point of integration for pod dependencies.

Each pod is integrated as a repository and each repository is self contained.

By declaring a `new_pod_repository`, the dependency is available to all Bazel
targets.

### Naming Convention

In Bazel a label is a build target identifier. Pod labels are all formed using
the same logic. _The remainder of this document uses the `Vendor` convention._

The first part of the label is the package name, followed by the name of the
target: `//Vendor/__PACKAGE__:__TARGET__`

The top level target is determined by the root subspec.

For example, in `PINCache`, the root target's label is `//Vendor/PINCache:PINCache`.

Subspecs targets have the same name as the subspec. For example, the label of the
subpsec `Core` in `PINCache` is `//Vendor/PINCache:Core`

### Dependencies on Pods

Transitive dependencies must be declared in the `Pods.WORKSPACE`.

Dependencies between targets are resolved through an idiomatic naming
convention.

For example, `PINCache` depends on `PINOperation`. In `PINCache`'s `BUILD` file,
the dependency on `//Vendor/PINOperation:PINOperation` is generated. The `WORKSPACE`
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

Upon updating pods, the local files are sym-linked into the pod directory.

This can aid in local development of Pod dependencies, and was originally
designed for such a use case.

### Resolving issues with dependencies

Many dependencies will work with `new_pod_repository` without any special
considerations: just add the `name`, and `url`.

Some dependencies may not. The `install_script` attribute is a way to resolve
issues with such dependencies.

For example, in `PINRemoteImage` source files are in folders that have spaces in
the name. This is not supported in Bazel. Please see the [Known
complications section](#known-complications) for more info.

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
`//Vendor/__PACKAGE__:$__POD_NAME___acknowledgment`

Merge all of the dependencies into `Settings.bundle`

```
load("@rules_pods//BazelExtensions:extensions.bzl", "acknowledgments_plist")

# Example `Settings`.bundle target
objc_bundle_library(
    name = "Settings",
    resources = ["Root.plist", "acknowledgements"],
    visibility = ['//visibility:public'],
)

ALL_POD_DEPS = ["//Vendor/PINOperation:PINOperation", "//Vendor/PINCache:PINCache"]
acknowledgments_plist(
    name = "acknowledgements",
    deps = [d + "_acknowledgement" for d in ALL_POD_DEPS],
    merger = "//Vendor/rules_pods/BazelExtensions:acknowledgement_merger"
)
```

### `new_pod_repository` API reference

`name`: the name of this repo

`url`: the url of this repo

`podspec_url`: an override podspec file. Can be either a URL or a Bazel
label (when used as a workspace rule) or a relative or absolute path to
a file (when used in vendored mode).

By default, we will look in the root of the repository, and read a .podspec file.
This requires having CocoaPods installed on build nodes. If a JSON podspec is
provided here, then it is not required to run CocoaPods.

`strip_prefix`: a directory prefix to strip from the extracted files. Many
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

`repo_tools`: a mapping of executables in Bazel to command names. If we are
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

Some code, like [Texture](https://github.com/pinterest/PodToBUILD/tree/master/Examples/Texture), uses
`__has_include` to conditionally include code.

In Bazel, if that include is not explicitly added, then this feature will not
work. In this case, use a `user_option` to add dependencies available on the
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
of `SPUserResizableView+Pion`.

This should eventually be handled by default.


## FAQ

### How many pods are supported?

Most ObjC/C++/C Pods should work out of the box and the goal is support all
CocoaPods. _Please do file issues and PRs for pods that don't work._

### Does it work with Swift?

The short answer is yes, but probably not. Swift support in `rules_pods`, and
Bazel ( `swift_library` / `rules_swift` ) is still under development.

### Should I do source builds of rules_pods?

The short answer is probably not. Consider that building `rules_pods` along with
an iOS application ties the build environment of `rules_pods` to that of the iOS
application. This includes the Bazel rules version and swift version. In
addition to coupling the environment, it may be slow overall.

However, `update_pods` automatically does source builds of `rules_pods` with
Bazel if it is checked out as such. Simply use `git_repository` instead of
`http_archive` as mentioned in the quickstart guide. `building` with Bazel isn't
well supported in `repository_rules`, and isn't supported at the moment.

### How do I update rules_pods?

See the [quickstart
instructions](https://github.com/pinterest/PodToBUILD/tree/master#quickstart-instructions).

### How can I generate an Xcode project for Bazel built pods?

Please find info in the [Bazel
documentation](https://docs.bazel.build/versions/master/migrate-xcode.html).

### How can I build an iOS applicaiton with Bazel with CocoaPod dependencies?

The documentation of building an iOS application resides in the [Bazel
documentation](https://docs.bazel.build/versions/master/tutorial/ios-app.html).
This README and examples are intended to cover the rest.

### How can I develop rules_pods?

`make` is the canonical build system of `rules_pods` - see the `Makefile` for up
to date development workflows.

The [examples](https://github.com/pinterest/PodToBUILD/tree/master/Examples) are intended to be tested, minimal, end to end, use cases of
`rules_pods`. The examples do a source build of `rules_pods`, and setup pods.
Simply cd into an example, and run `make`.

For developing the `BUILD` file compiler, use `make run EXAMPLE=_some pod_`

Additionally, Xcode development is supported via Swift Package Manager. To
generate an Xcode project, run:
```
swift package generate-xcodeproj
```

PRs welcome :)!

