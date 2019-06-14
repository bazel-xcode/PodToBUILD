.PHONY: build 
build: CONFIG= debug
build: SWIFT_OPTS= --configuration $(CONFIG)
build: build-impl-spm

# There are a few issues with SwiftPackageManager and incremental builds
clean:
	rm -rf .build
	tools/bazelwrapper clean

compiler: release

repo-tools: release

release-spm: CONFIG = release
release-spm: SWIFT_OPTS= --configuration $(CONFIG) -Xswiftc -static-stdlib
release-spm: build-impl-spm
release-spm:
	@ditto .build/$(CONFIG)/Compiler bin/Compiler
	@ditto .build/$(CONFIG)/RepoTools bin/RepoTools

build-impl-spm:
	@mkdir -p .build
	swift build $(SWIFT_OPTS) \
	    -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13 \
		| tee .build/last_build.log; \
		exit $${PIPESTATUS[0]}

# Tee the error to a log file
# Summarize the status
# Exit with the status
test-impl:
	@mkdir -p .build
	swift test $(SWIFT_TEST_OPTS) \
	    -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13 \
		2>&1 | tee .build/last_build.log; \
		echo "SWIFT_TEST_STAT=$${PIPESTATUS[0]}" >> .build/last_build.log
	@grep  -A 1 'Test Suite' .build/last_build.log
	@grep SWIFT_TEST_STAT=0 .build/last_build.log || exit 1

# Update the gold master directory
goldmaster: release
	@./MakeGoldMaster.sh

unit-test: SWIFT_TEST_OPTS= --filter PodToBUILDTests
unit-test: test-impl


# Running this is non trival from within the SwiftTest - do it here.
install-bazel:
	./tools/bazelwrapper info

SANDBOX=/var/tmp/PodTestSandbox
init-sandbox: install-bazel release
	rm -rf $(SANDBOX)
	mkdir -p $(SANDBOX)

.PHONY: build-test
build-test: SWIFT_TEST_OPTS= --filter BuildTests*
build-test: init-sandbox 
build-test: test-impl

# Run the integration tests a few times. We want to make sure output is working
# and stable.
integration-test: release
	for i in $$(seq 1 10); do ./IntegrationTests/RunTests.sh; done

test: test-impl integration-test

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

# https://github.com/swift-vim/SwiftPackageManager.vim
compile_commands.json:
	swift package clean
	which spm-vim
	swift build --build-tests \
		-Xswiftc -parseable-output | tee .build/commands_build.log
	cat .build/commands_build.log | spm-vim compile_commands



TESTED_BAZEL_VERSION=0.25.2

# Make a binary archive of PodToBUILD with the official github cli `hub`
github_release:
	@which hub || (echo "this command relies on github cli" && exit 1)
	@git diff --quiet || echo "Dirty tree" && exit 1
	@git checkout master
	@git pull --rebase origin master
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

