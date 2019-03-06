#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used to manipulate tokens

# verify the result of the end-to-end test
verifyOutput() {
    s=$1
    if [[ ! "$(cat log.txt)" == *"$s"* ]]; then
        echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
        echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
        echo
        exit 1
    fi
}

countTokens() {
    EXPECTED=$1
    echo ${EXPECTED}

    filename="log.txt"
    COUNTER=0
    while read -r line; do
        name="$line"
        echo $name
        let COUNTER=COUNTER+1
    done < "$filename"
    let COUNTER=COUNTER/2
    if [[ $COUNTER -ne ${EXPECTED} ]]; then
        echo "Expected" ${EXPECTED} " got " $COUNTER
        echo
        echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
        echo
        exit 1
    fi
}

getTokens() {
    filename="log.txt"
    TOKENIDS="["
    COUNTER=0
    while read -r line; do
        name="$line"
        if [[ $(($COUNTER % 2)) == 0 ]]; then
#             Token id here
            if [[ $(($COUNTER)) == 0 ]]; then
                TOKENIDS=$TOKENIDS$name
            else
                TOKENIDS=$TOKENIDS","$name
            fi
        fi
        let COUNTER=COUNTER+1
    done < "$filename"
    TOKENIDS=$TOKENIDS"]"
    echo $TOKENIDS
}

issueTokens() {
    CONFIG_FILE=$1
    SENDER=$2
    TYPE=$3
    QUANTITY=$4
    RECIPIENT=$5

    set -x
    token issue --config $CONFIG_FILE --mspPath $SENDER --channel $CHANNEL_NAME --type $TYPE --quantity $QUANTITY --recipient $RECIPIENT >&log.txt
    res=$?
    set +x
    cat log.txt
    verifyResult $res "Failed Issue"

    OUTPUT='Orderer Status [SUCCESS]
Committed [true]
'
    verifyOutput $OUTPUT "Failed Issue"
}

listTokens() {
    CONFIG_FILE=$1
    SENDER=$2

    set -x
    token list --config $CONFIG_FILE --mspPath $SENDER --channel $CHANNEL_NAME >&log.txt
    res=$?
    set +x
#    cat log.txt
    verifyResult $res "Failed List Tokens"
}

transferTokens() {
    CONFIG_FILE=$1
    SENDER=$2
    TOKEN_IDS=$3
    SHARES=$4

    set -x
    token transfer --config $CONFIG_FILE --mspPath $SENDER --channel $CHANNEL_NAME --tokenIDs $TOKEN_IDS --shares $SHARES >&log.txt
    res=$?
    set +x
#    cat log.txt
    verifyResult $res "Failed Transfer"
    OUTPUT='Orderer Status [SUCCESS]
Committed [true]
'
    verifyOutput $OUTPUT "Failed Transfer"
}

redeemTokens() {
    CONFIG_FILE=$1
    SENDER=$2
    TOKEN_IDS=$3
    QUANTITY=$4

    set -x
    token redeem --config $CONFIG_FILE --mspPath $SENDER --channel $CHANNEL_NAME --tokenIDs $TOKEN_IDS --quantity $QUANTITY >&log.txt
    res=$?
    set +x
#    cat log.txt
    verifyResult $res "Failed Transfer"
    OUTPUT='Orderer Status [SUCCESS]
Committed [true]
'
    verifyOutput $OUTPUT "Failed Redeem"
}