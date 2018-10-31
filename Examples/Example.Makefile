# This Makefile does some odd things to setup testing conditions
# and install Bazel.
# Please see the `README` for regular usage
RULES_PODS_DIR=$(shell echo $$(dirname $$(dirname $$PWD)))
BAZEL_WRAPPER=$(RULES_PODS_DIR)/tools/bazelwrapper

# Workaround for symlink weirdness.
# Currently `bazelwrapper` relies on pwd, which causes issues here
BAZEL=~/.bazelenv/versions/0.18.0/bin/bazel

all: fetch build

# Build everything in this workspace
.PHONY: build
build: info 
	$(BAZEL) build :* --override_repository=rules_pods=$(RULES_PODS_DIR)

test: info 
	$(BAZEL) test :* --override_repository=rules_pods=$(RULES_PODS_DIR)

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

