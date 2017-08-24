#!/bin/bash

set -e

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"
cd $SCRIPTPATH

mkdir -p bin/

BUILD_DIR=tmp_build_dir
mkdir -p BUILD_DIR


xcodebuild  \
-project PodSpecToBUILD.xcodeproj \
-scheme RepoTools \
-configuration Release \
-derivedDataPath $PWD/$BUILD_DIR

ditto $BUILD_DIR/Build/Products/Release/RepoTools bin/
