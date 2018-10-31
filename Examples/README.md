# PodToBUILD Examples

CI tested, usage examples of using CocoaPods with Bazel via `PodToBUILD`.

_Note, that the installation of `rules_pods` is non-normal and setup for testing
conditions - see the README.md for more info._

Each example directory contains:
- a `BUILD` file. Under tests, Bazel builds the targets defined here
- a `WORKSPACE` file. ( Generally empty )
- a `Makefile`. Generally, a symlink to the `Example.Makefile` which is used for
  testing. It is expected that `make` will do everything relevant to verify this
  example.

