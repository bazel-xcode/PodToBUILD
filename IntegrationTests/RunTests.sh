SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"
pushd "$SCRIPTPATH/../.." > /dev/null

cd $SCRIPTPATH/../
echo $PWD

make compiler
CMD=bin/PodSpecToBUILD

# Loop through all the examples and compare outputs
for f in $(find Examples/*); do
    GOLD_MASTER=`cat IntegrationTests/GoldMaster/$(basename $f).goldmaster`
    OUTPUT=$($CMD $f)

    if [[ "$OUTPUT" == "$GOLD_MASTER" ]]; then
        echo "PASS $f"
    else
        echo "EXPECTED $GOLD_MASTER"
        echo "GOT $OUTPUT"
        echo "FAILURE $f"
    fi
done
