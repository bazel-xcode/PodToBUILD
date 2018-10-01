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
		| tee .build/last_build.log

test-impl:
	@mkdir -p .build
	swift test $(SWIFT_TEST_OPTS) \
	    -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13 \
		| tee .build/last_build.log

# Update the gold master directory
goldmaster: release
	./MakeGoldMaster.sh

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
	.build/debug/Compiler Examples/$(POD)*

# We're running into issues with SwiftPackageManager's
# Build system on the CI. Blow away it's state
ci: clean test

release:
	tools/bazelwrapper build :RepoTools :Compiler
	ditto bazel-bin/RepoTools bin/RepoTools
	ditto bazel-bin/Compiler bin/Compiler


# https://github.com/swift-vim/SwiftPackageManager.vim
compile_commands.json:
	swift package clean
	which spm-vim
	swift build --build-tests \
		-Xswiftc -parseable-output | tee .build/commands_build.log
	cat .build/commands_build.log | spm-vim compile_commands

