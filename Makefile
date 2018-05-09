.PHONY : \
	build \
	release \
	goldmaster \
	test \
	unit-test \
	integration-test

build: CONFIG = debug
build: SWIFTBFLAGS = --configuration $(CONFIG)
build: build-impl

clean:
	rm -rf .build/debug
	rm -rf .build/release

compiler: release

repo-tools: release

release: CONFIG = release
release: SWIFTBFLAGS = --configuration $(CONFIG) -Xswiftc -static-stdlib
release: build-impl
release:
	ditto .build/$(CONFIG)/Compiler bin/Compiler
	ditto .build/$(CONFIG)/RepoTools bin/RepoTools

build-impl:
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

