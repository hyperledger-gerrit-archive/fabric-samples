#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFTN) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=10

if [ "$LANGUAGE" = "node" ]; then
    CC_SRC_PATH="/opt/gopath/src/github.com/hyperledger/fabric-samples/chaincode/abstore/node/"
elif [ "$LANGUAGE" = "java" ]; then
    CC_SRC_PATH="/opt/gopath/src/github.com/hyperledger/fabric-samples/chaincode/abstore/java/"
else
    CC_SRC_PATH="github.com/hyperledger/fabric-samples/chaincode/abstore/go/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh
. scripts/token.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.org${org} joined channel '$CHANNEL_NAME' ===================== "
		sleep $DELAY
		echo
	    done
	done
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for org1..."
updateAnchorPeers 0 1
echo "Updating anchor peers for org2..."
updateAnchorPeers 0 2

## Token E2E

echo "Issue 100 sun Tokens to User1@org1.example.com..."
issueTokens /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/configorg1.json \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    sun \
    100 \
    Org1MSP:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp
echo "Issue 50 sun Tokens to User1@org1.example.com..."
issueTokens /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/configorg1.json \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    sun \
    50 \
    Org1MSP:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp

echo "List Tokens belonging to Admin@org1.example.com. Must be empty..."
listTokens /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/configorg1.json \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
countTokens 0

echo "List Tokens belonging to User1@org1.example.com. Must contain one sun token of 100 units"
listTokens /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/configorg1.json \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp
countTokens 2

echo "User1@org1.example.com transfers to User1@org1.example.com and User1@org2.example.com"
transferTokens /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/configorg1.json \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp \
    $(getTokens) \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/shares.json

echo "List Tokens belonging to User1@org2.example.com."
listTokens /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/configorg2.json \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/User1@org2.example.com/msp
countTokens 2

echo "List Tokens belonging to User1@org1.example.com."
listTokens /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/configorg1.json \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp
countTokens 2

echo "Reedem 25 Sun Tokens belonging to User1@org1.example.com."
redeemTokens /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/configorg1.json \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp \
    $(getTokens) \
    25

echo "List Tokens belonging to User1@org1.example.com."
listTokens /opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/configorg1.json \
    /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp
countTokens 1

echo
echo "========= All GOOD, BYFTN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
