.PHONY : \
	build \
	releases \
	goldmaster \
	test \
	integration-test

build:
	BUILD_DIR=tmp_build_dir \
	xcodebuild  \
	-project PodSpecToBUILD.xcodeproj \
	-scheme PodSpecToBUILD \
	-configuration Debug \
	-derivedDataPath $PWD/$BUILD_DIR

# This program builds a release build of all the binaries
releases:
	./BuildReleases.sh

# Update the gold master directory
goldmaster:
	./MakeGoldMaster.sh

# Unit tests
test:
	xcodebuild  \
	-project PodSpecToBUILD.xcodeproj \
	-scheme PodSpecToBUILDTests \
	-configuration Debug \
	test

integration-test:
	./IntegrationTests/RunTests.sh

