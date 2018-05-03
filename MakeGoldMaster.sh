#!/bin/bash

set -e

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"
cd $SCRIPTPATH

mkdir -p IntegrationTests/GoldMaster

CMD=bin/Compiler

for f in $(find Examples/*); do
    $CMD $f > IntegrationTests/GoldMaster/$(basename $f).goldmaster
done
