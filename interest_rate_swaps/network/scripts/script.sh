#!/bin/bash

CHANNEL_NAME="irs"
DELAY="3"
TIMEOUT="10"
VERBOSE="false"
COUNTER=1
MAX_RETRY=5

CC_SRC_PATH="irscc/"

echo "Channel name : "$CHANNEL_NAME

createChannel() {
	CORE_PEER_LOCALMSPID=partya
	CORE_PEER_ADDRESS=irs-partya:7051
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partya.example.com/users/Admin@partya.example.com/msp
	echo "===================== Creating channel ===================== "
	peer channel create -o irs-orderer:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx
	echo "===================== Channel created ===================== "
}

joinChannel () {
	for org in partya partyb partyc auditor rr_provider
	do
		CORE_PEER_LOCALMSPID=$org
		CORE_PEER_ADDRESS=irs-$org:7051
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$org.example.com/users/Admin@$org.example.com/msp
		echo "===================== Org $org joining channel ===================== "
		peer channel join -b irs.block -o irs-orderer:7050
		echo "===================== Channel joined ===================== "
	done
}

installChaincode() {
	for org in partya partyb partyc auditor rr_provider
	do
		CORE_PEER_LOCALMSPID=$org
		CORE_PEER_ADDRESS=irs-$org:7051
		CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/$org.example.com/users/Admin@$org.example.com/msp
		echo "===================== Org $org installing chaincode ===================== "
		peer chaincode install -n irscc -v 0 -l golang -p  ${CC_SRC_PATH}
		echo "===================== Org $org chaincode installed ===================== "
	done
}

instantiateChaincode() {
	CORE_PEER_LOCALMSPID=partya
	CORE_PEER_ADDRESS=irs-partya:7051
	CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partya.example.com/users/Admin@partya.example.com/msp
	echo "===================== Instantiating chaincode ===================== "
	peer chaincode instantiate -o irs-orderer:7050 -C $CHANNEL_NAME -n irscc -l golang -v 0 -c '{"Args":["init","auditor","100000","rr_provider","libor"]}' -P "OR ('partya.peer','auditor.peer')"
	echo "===================== Chaincode instantiated ===================== "
}


## Create channel
sleep 1
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Install chaincode on all peers
echo "Installing chaincode..."
installChaincode

# Instantiate chaincode
echo "Instantiating chaincode..."
instantiateChaincode

echo
echo "========= IRS network sample setup completed =========== "
echo

exit 0
