#!/bin/bash

set -e

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"
cd $SCRIPTPATH

mkdir -p IntegrationTests/GoldMaster

for f in $(find Examples/*); do
    bin/Compiler $f --always_split_rules \
        > IntegrationTests/GoldMaster/$(basename $f).goldmaster
done
