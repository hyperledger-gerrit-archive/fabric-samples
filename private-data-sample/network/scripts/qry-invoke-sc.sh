#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
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
MAX_RETRY=5

CC_SRC_PATH="github.com/chaincode/auction/"

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

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



# Invoke chaincode on peer0.org1 and peer0.org2
#echo "Sending registerUser seller invoke transaction on peer0.org1 ..."
#registerUser 0 1 org1-jim 1000 dollars seller
#
#echo "Sending registerUser seller invoke transaction on peer0.org1 ..."
#registerUser 0 1 org1-jon 1000 dollars seller
#
#echo "Sending registerUser buyer invoke transaction on peer0.org1 ..."
#registerUser 0 2 org2-sam 2000 dollars buyer
#
#echo "Sending registerUser buyer invoke transaction on peer0.org1 ..."
#registerUser 0 2 org2-sally 2000 dollars buyer

# Invoke chaincode on peer0.org1 and peer0.org2
echo "Sending createItem invoke transaction on peer0.org1 ..."
createItem "0" "1" "mobile" "smartphone" "electronic" "dollars" "150" "250" "Org1-Jim9" "20-10-2018 09:00:00" "21-10-2018 00:00:00"
#
#echo "Sending createItem invoke transaction on peer0.org1 ..."
#createItem "0" "1" "table" "small laptop table" "furniture" "dollars" "50" "75" "org1-jon" "10-10-2018 09:00:00" "12-10-2018 00:00:00"

#echo "Querying chaincode on peer0.org1..."
#listItems 0 1 "org1-jim"
#
#echo "Querying chaincode on peer0.org1..."
#listItems 0 1 "org1-jon"

#echo "Sending placeBid (mobile) invoke transaction on peer0.org1 ..."
#placeBid "0" "1" "ITEM-08872ef1defcb849f6674c9f2f25ddb8797dadaa2fed4f4168246e5596a287df" "250" "org2-sam" 
#
#echo "Sending placeBid(Table) invoke transaction on peer0.org1 ..."
#placeBid "0" "1" "ITEM-9ebf782d80e202e6be7cfaef309343e2bd0915a5e58cb545403abee4d18031fc" "255" "org2-sally" 

#echo "Sending placeBid (less than minBid) invoke transaction on peer0.org1 ..."
#placeBid "0" "1" "ITEM-9ebf782d80e202e6be7cfaef309343e2bd0915a5e58cb545403abee4d18031fc" "25" "org2-sally" 

#echo "Sending placeBid (more than avlBal) invoke transaction on peer0.org1 ..."
#placeBid "0" "1" "ITEM-9ebf782d80e202e6be7cfaef309343e2bd0915a5e58cb545403abee4d18031fc" "2500" "org2-sally" 

#echo "Sending placeBid (raising bid  =on mobile) invoke transaction on peer0.org1 ..."
#placeBid "0" "1" "ITEM-08872ef1defcb849f6674c9f2f25ddb8797dadaa2fed4f4168246e5596a287df" "275" "org2-sally" 

#echo "Querying chaincode on peer0.org2..."
#listItems 0 2 "org2-sam"
#
#echo "Querying chaincode on peer0.org2..."
#listItems 0 2 "org2-sally"

#echo "Sending placeBid (mobile- raise bid) invoke transaction on peer0.org1 ..."
#placeBid "0" "1" "ITEM-08872ef1defcb849f6674c9f2f25ddb8797dadaa2fed4f4168246e5596a287df" "280" "org2-sam" 

#echo "Sending placeBid (raising bid  =on mobile) invoke transaction on peer0.org1 ..."
#placeBid "0" "1" "ITEM-08872ef1defcb849f6674c9f2f25ddb8797dadaa2fed4f4168246e5596a287df" "285" "org2-sally" 

#echo "Sending auction invoke transaction on peer0.org1 ..."
#auctionItem "0" "1" "ITEM-08872ef1defcb849f6674c9f2f25ddb8797dadaa2fed4f4168246e5596a287df"


echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
