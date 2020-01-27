SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"
pushd "$SCRIPTPATH/../.." > /dev/null

cd $SCRIPTPATH/../
echo $PWD

make compiler
CMD=bin/Compiler

# Loop through all the examples and compare outputs
for f in $(find Examples/PodSpecs/*); do
    GOLD_MASTER=`cat IntegrationTests/GoldMaster/$(basename $f).goldmaster`
    TEMP_F=$(mktemp)
    OUTPUT=$($CMD $f | tee $TEMP_F)

    if [[ "$OUTPUT" == "$GOLD_MASTER" ]]; then
        echo "PASS $f"
    else
        echo "EXPECTED $GOLD_MASTER"
        echo "===BEGIN OUTPUT==="
        echo "$OUTPUT"
        echo "===END OUTPUT==="
        echo "===BEGIN DIFF==="
        echo "$(diff IntegrationTests/GoldMaster/$(basename $f).goldmaster $TEMP_F)"
        echo "===END DIFF==="
        echo "FAILURE $f"
        exit 1
    fi
done


# Test that acknowledgement plist generation works
tools/bazelwrapper build --incompatible_depset_is_not_iterable=false IntegrationTests/Acknowlegements/...
