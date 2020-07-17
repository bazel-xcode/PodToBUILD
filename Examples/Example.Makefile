# This Makefile does some odd things to setup testing conditions
# and install Bazel.
# Please see the `README` for regular usage
RULES_PODS_DIR=$(shell echo $$(dirname $$(dirname $$PWD)))

# Workaround for symlink weirdness.
# Currently `bazelwrapper` relies on pwd, which causes issues here
BAZEL=~/.bazelenv/versions/0.28.1/bin/bazel

# Override the repository to point at the source. It does a source build of the
# current code.
# TODO: there's an issue with non hermetic headers in the PINRemoteImage example
REPOSITORY_OVERRIDE=--override_repository=rules_pods=$(RULES_PODS_DIR)
BAZEL_OPTS=$(REPOSITORY_OVERRIDE) -s \
	--disk_cache=$(HOME)/Library/Caches/Bazel \
	--spawn_strategy=standalone \
	--apple_platform_type=ios

all: pod_test fetch build

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

# This command generates a workspace from a Podfile
gen_workspace:
	make -C ../../ build
	[[ ! -f Podfile ]]  ||../../bin/RepoTools generate_workspace > Pods.WORKSPACE

