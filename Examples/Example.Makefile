# This Makefile does some odd things to setup testing conditions
# and install Bazel.
# Please see the `README` for regular usage
RULES_PODS_DIR=$(shell echo $$(dirname $$(dirname $$PWD)))

BAZEL=../../tools/bazel

# Override the repository to point at the source. It does a source build of the
# current code.
# TODO: there's an issue with non hermetic headers in the PINRemoteImage example
REPOSITORY_OVERRIDE=--override_repository=rules_pods=$(RULES_PODS_DIR)
BAZEL_OPTS=$(REPOSITORY_OVERRIDE) \
	--disk_cache=$(HOME)/Library/Caches/Bazel \
	--spawn_strategy=local \
	--apple_platform_type=ios

all: bootstrap pod_test fetch build

# Some examples require out of band loading
bootstrap:
	[[ ! -x bootstrap.sh ]] || ./bootstrap.sh
# This command ensures that cocoapods is installed on the host
pod_test:
	pod --version

# Build everything in this workspace
.PHONY: build
build: info
	$(BAZEL) build :* $(BAZEL_OPTS)

test: info
	$(BAZEL) test :* $(BAZEL_OPTS)

# Fetch vendored pods if there's a Pods.WORKSPACE. In normal operation it isn't
# expected to run `update_pods` along with a build.
#
# Generally, this would be ran when dependencies are updated, and then,
# dependencies _would_ be checked in.
vendorize:
	$(BAZEL) run @rules_pods//:update_pods $(BAZEL_OPTS) -- --src_root $(PWD)
	# The above is similar to running ../../bin/update_pods.py --src_root $(PWD)
	# however, `rules_pods` is overriden
	ditto $(RULES_PODS_DIR)/BazelExtensions Vendor/rules_pods/BazelExtensions

fetch: info
	[[ ! -f Pods.WORKSPACE ]] || $(MAKE) vendorize
	$(BAZEL) fetch :* $(REPOSITORY_OVERRIDE)

info:
	$(BAZEL) info $(REPOSITORY_OVERRIDE)

update_xcodeproj:
	[[ ! -d PodsHost ]] || rm -rf PodsHost
	ditto ../.PodsHost PodsHost
	pod install

# This command generates a workspace from a Podfile
gen_podfile_deps:
	make -C ../../ build
	[[ ! -f Podfile ]]  ||../../bin/RepoTools generate_workspace > podfile_deps.py

