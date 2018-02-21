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
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
        CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

setOrdererGlobals() {
        CORE_PEER_LOCALMSPID="OrdererMSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/users/Admin@example.com/msp
}

signing() {
        setGlobals 0 $1
        peer channel signconfigtx -f config_update_in_envelope.pb
}

fetchConfig() {
        CH_NAME=$1
        CONFIGTXLATOR_URL=http://127.0.0.1:7059
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CH_NAME --cafile $ORDERER_CA 
        else
                peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CH_NAME --tls --cafile $ORDERER_CA
        fi
        curl -X POST --data-binary @config_block.pb "$CONFIGTXLATOR_URL/protolator/decode/common.Block" | jq . > config_block.json
        jq .data.data[0].payload.data.config config_block.json > config.json
}

configUpdate() {
        CH_NAME=$1
        GROUP=$2
        curl -X POST --data-binary @config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > config.pb
        curl -X POST --data-binary @modified_config.json "$CONFIGTXLATOR_URL/protolator/encode/common.Config" > modified_config.pb
        curl -X POST -F channel=$CH_NAME -F "original=@config.pb" -F "updated=@modified_config.pb" "${CONFIGTXLATOR_URL}/configtxlator/compute/update-from-configs" > config_update.pb
        curl -X POST --data-binary @config_update.pb "$CONFIGTXLATOR_URL/protolator/decode/common.ConfigUpdate" | jq . > config_update.json
        echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CH_NAME'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . > config_update_in_envelope.json
        curl -X POST --data-binary @config_update_in_envelope.json "$CONFIGTXLATOR_URL/protolator/encode/common.Envelope" > config_update_in_envelope.pb
        if [ $CH_NAME != "testchainid" ] && [ $GROUP == "channel" ]; then
               signing 1
               signing 2
               setOrdererGlobals
        elif [ $CH_NAME != "testchainid" ] && [ $GROUP = "application" ]; then
               signing 1
               setGlobals 0 2
        fi
}

configGroup() {
        CH_NAME=$1
        GROUP=$2
        setOrdererGlobals
        fetchConfig $CH_NAME
        if [ $GROUP == "orderer" ]; then
                jq -s '.[0] * {"channel_group":{"groups":{"Orderer": {"values": {"Capabilities": .[1]}}}}}' config.json ./scripts/capabilities.json > modified_config.json
        elif [ $GROUP == "channel" ]; then
                jq -s '.[0] * {"channel_group":{"values": {"Capabilities": .[1]}}}' config.json ./scripts/capabilities.json > modified_config.json
        elif [ $GROUP == "application" ]; then
                jq -s '.[0] * {"channel_group":{"groups":{"Application": {"values":.[1]}}}}' config.json ./scripts/capabilities_application.json > modified_config.json
        fi
        configUpdate $CH_NAME $GROUP
        peer channel update -f config_update_in_envelope.pb -c $CH_NAME -o orderer.example.com:7050 --tls true --cafile $ORDERER_CA
        res=$?
        verifyResult $res "Config update for \"$GROUP\" on \"$CH_NAME\" failed"
        echo "===================== Config Channel \"$CH_NAME\" is completed ===================== "

}

echo "Installing jq"
apt-get update
apt-get install -y jq vim

echo "Config update...."
configtxlator start &

sleep 3

echo "Config update for /Channel/Orderer"
configGroup testchainid orderer

sleep 5

echo "Config update for /Channel"
configGroup testchainid channel

#Query on chaincode on Peer0/Org1
echo "Querying chaincode on org1/peer0..."
chaincodeQuery 0 1 90

##Invoke on chaincode on Peer0/Org1
echo "Sending invoke transaction on org1/peer0..."
chaincodeInvoke 0 1

#Query on chaincode on Peer0/Org1
echo "Querying chaincode on org1/peer0..."
chaincodeQuery 0 1 80

echo "Config update for /Channel/Orderer on mychannel"
configGroup mychannel orderer

sleep 5

echo "Config update for channel group on mychannel"
configGroup mychannel channel

#Query on chaincode on Peer0/Org2
echo "Querying chaincode on org2/peer0..."
chaincodeQuery 0 2 80

##Invoke on chaincode on Peer0/Org2
echo "Sending invoke transaction on org1/peer0..."
chaincodeInvoke 0 2

echo "Config update for Application capabilities on mychannel"
configGroup mychannel application

#Query on chaincode on Peer0/Org1
echo "Querying chaincode on org1/peer0..."
chaincodeQuery 0 2 70

echo
echo "===================== All GOOD, End-2-End UPGRADE Scenario execution completed ===================== "
echo

echo
echo " _____   _   _   ____            _____   ____    _____ "
echo "| ____| | \ | | |  _ \          | ____| |___ \  | ____|"
echo "|  _|   |  \| | | | | |  _____  |  _|     __) | |  _|  "
echo "| |___  | |\  | | |_| | |_____| | |___   / __/  | |___ "
echo "|_____| |_| \_| |____/          |_____| |_____| |_____|"
echo

exit 0
