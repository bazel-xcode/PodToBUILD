# This Makefile does some odd things to setup testing conditions
# and install Bazel.
# Please see the `README` for regular usage
RULES_PODS_DIR=$(shell echo $$(dirname $$(dirname $$PWD)))
BAZEL_WRAPPER=$(RULES_PODS_DIR)/tools/bazelwrapper

# Workaround for symlink weirdness.
# Currently `bazelwrapper` relies on pwd, which causes issues here
BAZEL=~/.bazelenv/versions/0.25.2/bin/bazel

# Override the repository to point at the source. It does a source build of the
# current code.
BAZEL_OPTS=--override_repository=rules_pods=$(RULES_PODS_DIR) \
		--disk_cache=$(HOME)/Library/Caches/Bazel  --apple_platform_type=ios

all: fetch build

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
	$(RULES_PODS_DIR)/bin/update_pods.py --src_root $(PWD)
	ditto $(RULES_PODS_DIR)/BazelExtensions Vendor/rules_pods/BazelExtensions

fetch: info 
	[[ ! -f Pods.WORKSPACE ]] || $(MAKE) vendorize
	$(BAZEL) fetch :* --override_repository=rules_pods=$(RULES_PODS_DIR)

info:
	$(BAZEL_WRAPPER) info

