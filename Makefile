.PHONY : \
	build \
	releases \
	goldmaster \
	test \
	unit-test \
	integration-test \
	workspace-tools

build:
	xcodebuild  \
	-project PodSpecToBUILD.xcodeproj \
	-scheme PodSpecToBUILD \
	-configuration Debug \
	-derivedDataPath tmp_build_dir

clean:
	rm -rf tmp_build_dir

compiler:
	xcodebuild  \
	-project PodSpecToBUILD.xcodeproj \
	-scheme PodSpecToBUILD \
	-configuration Release \
	-derivedDataPath tmp_build_dir
	ditto tmp_build_dir/Build/Products/Release/PodSpecToBUILD bin/

repo-tools:
	xcodebuild  \
	-project PodSpecToBUILD.xcodeproj \
	-scheme RepoTools \
	-configuration Release \
	-derivedDataPath tmp_build_dir
	ditto tmp_build_dir/Build/Products/Release/RepoTools bin/

workspace-tools:
	xcodebuild  \
	-project PodSpecToBUILD.xcodeproj \
	-scheme WorkspaceTools \
	-configuration Release \
	-derivedDataPath tmp_build_dir
	ditto tmp_build_dir/Build/Products/Release/WorkspaceTools bin/

# This program builds a release build of all the binaries
releases:
	./BuildReleases.sh

# Update the gold master directory
goldmaster:
	./MakeGoldMaster.sh

# Unit tests
unit-test:
	xcodebuild  \
	-project PodSpecToBUILD.xcodeproj \
	-scheme PodSpecToBUILDTests \
	-configuration Release \
	test

integration-test:
	./IntegrationTests/RunTests.sh

test: unit-test integration-test


