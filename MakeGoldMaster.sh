#!/bin/bash

set -e

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"
cd $SCRIPTPATH

mkdir -p IntegrationTests/GoldMaster

BUILD_DIR=tmp_build_dir
xcodebuild  \
-project PodSpecToBUILD.xcodeproj \
-scheme PodSpecToBUILD \
-configuration Release \
-derivedDataPath $PWD/$BUILD_DIR

CMD=$BUILD_DIR/Build/Products/Release/PodSpecToBUILD

for f in $(find Examples/*); do
    $CMD $f > IntegrationTests/GoldMaster/$(basename $f).goldmaster
done
