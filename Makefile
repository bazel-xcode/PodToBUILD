.PHONY : \
	build \
	release \
	release-spm \
	goldmaster \
	test \
	unit-test \
	integration-test \
	compile_commands.json

build: CONFIG = debug
build: SWIFTBFLAGS = --configuration $(CONFIG)
build: build-impl-spm

clean:
	rm -rf .build/debug
	rm -rf .build/release
	tools/bazelwrapper clean

compiler: release

repo-tools: release

release-spm: CONFIG = release
release-spm: SWIFTBFLAGS = --configuration $(CONFIG) -Xswiftc -static-stdlib
release-spm: build-impl-spm
release-spm:
	@ditto .build/$(CONFIG)/Compiler bin/Compiler
	@ditto .build/$(CONFIG)/RepoTools bin/RepoTools


build-impl-spm:
	swift build $(SWIFTBFLAGS) \
	    -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13

# Update the gold master directory
goldmaster: release
	./MakeGoldMaster.sh

unit-test:
	swift test \
	    -Xswiftc -target -Xswiftc x86_64-apple-macosx10.13

integration-test: release
	./IntegrationTests/RunTests.sh

test: unit-test integration-test

release:
	tools/bazelwrapper build :RepoTools :Compiler
	@ditto bazel-bin/RepoTools bin/RepoTools
	@ditto bazel-bin/Compiler bin/Compiler


# https://github.com/swift-vim/SwiftPackageManager.vim
compile_commands.json:
	swift package clean
	which spm-vim
	swift build \
		-Xswiftc -parseable-output | tee .build/commands_build.log
	cat .build/commands_build.log | spm-vim compile_commands

