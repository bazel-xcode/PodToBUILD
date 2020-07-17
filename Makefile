.PHONY: build 
build:
	@tools/bazelwrapper build \
		--disk_cache=$(HOME)/Library/Caches/Bazel \
		--spawn_strategy=standalone \
		:RepoTools :Compiler
	@ditto bazel-bin/RepoTools bin/RepoTools
	@ditto bazel-bin/Compiler bin/Compiler


# There are a few issues with SwiftPackageManager and incremental builds
clean:
	rm -rf .build
	tools/bazelwrapper clean

compiler: release

repo-tools: release

# Update the gold master directory
goldmaster: build
	@./MakeGoldMaster.sh

unit-test: 
	tools/bazelwrapper test :PodToBUILDTests --test_strategy=standalone


# Running this is non trival from within the SwiftTest - do it here.
install-bazel:
	./tools/bazelwrapper info

SANDBOX=/var/tmp/PodTestSandbox
init-sandbox: install-bazel release
	rm -rf $(SANDBOX)
	mkdir -p $(SANDBOX)

# This command ensures that cocoapods is installed on the host
pod_test:
	pod --version

# There's a few issues running these tests under Bazel, some functionality will
# be different and have issues as Bazel doesn't run so well recursivly.
# For now:
# - build out a binary release
# - copy it to tmp so the examples can load it
# - run Bazel for all the examples
.PHONY: build-test
build-test: pod_test build archive init-sandbox 
	cd Examples/BasiciOS && make all
	cd Examples/PINRemoteImage && make all
	cd Examples/Texture && make all
	cd Examples/ChildPodspec && make all

build-example: EXAMPLE=Examples/PINCache.podspec.json
build-example: CONFIG = debug
build-example: build
	@ditto .build/$(CONFIG)/Compiler bin/Compiler
	@ditto .build/$(CONFIG)/RepoTools bin/RepoTools
	stat $(EXAMPLE) || exit 1
	bin/Compiler $(EXAMPLE)

integration-test: release
	for i in $$(seq 1 10); do ./IntegrationTests/RunTests.sh; done

test: build-test unit-test integration-test

# Run the BUILD compiler on an example
example: build
	.build/debug/Compiler Examples/$(POD)* --always_split_rules

# We're running into issues with SwiftPackageManager's
# Build system on the CI. Blow away it's state
ci: clean
	$(MAKE) unit-test
	$(MAKE) integration-test
	$(MAKE) build-test

release:
	@tools/bazelwrapper build \
		--disk_cache=$(HOME)/Library/Caches/Bazel \
		--spawn_strategy=standalone \
		-c opt \
		--swiftcopt=-whole-module-optimization :RepoTools :Compiler
	@ditto bazel-bin/RepoTools bin/RepoTools
	@ditto bazel-bin/Compiler bin/Compiler


TESTED_BAZEL_VERSION=0.25.2

# Make a binary archive of PodToBUILD with the official github cli `hub`
github_release:
	@which hub || (echo "this command relies on the hub tool. https://github.com/github/hub or 'brew install hub'." && exit 1)
	@git checkout master
	@git pull --rebase  origin master
	@echo "creating release: $(TESTED_BAZEL_VERSION)-($(shell git rev-parse --short HEAD)"
	$(MAKE) release
	$(MAKE) archive
	@hub release create -p -a PodToBUILD.zip \
   		-m "PodToBUILD  $(TESTED_BAZEL_VERSION)-$(shell git rev-parse --short HEAD)" \
		$(TESTED_BAZEL_VERSION)-$(shell git rev-parse --short HEAD)

# Create an archive of `rules_pods`.
# There should be no behaviorial differences between this package and a source
# checkout, other than the not building.
archive:
	$(eval BUILD_DIR=$(shell mktemp -d))
	@echo "Archiving to $(BUILD_DIR).."
	@ditto bin $(BUILD_DIR)/bin
	@ditto BazelExtensions $(BUILD_DIR)/BazelExtensions
	@echo "release:\n\t@echo 'skipping build..'" > $(BUILD_DIR)/Makefile
	@touch $(BUILD_DIR)/WORKSPACE
	@echo "alias(name = 'update_pods', actual = '//bin:update_pods')" \
		> $(BUILD_DIR)/BUILD
	@ditto LICENSE $(BUILD_DIR)/
	@cd $(BUILD_DIR) && zip -r \
		$(PWD)/PodToBUILD.zip \
		bin/* \
		BazelExtensions \
		Makefile \
		WORKSPACE \
		BUILD \
		LICENSE

