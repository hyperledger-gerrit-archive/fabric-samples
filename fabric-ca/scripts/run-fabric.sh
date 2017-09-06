#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

function main {

   # Wait for the create channel transaction file to exist
   waitForFile $CHANNEL_TX_FILE

   # Set ORDERER_PORT_ARGS to the args needed to communicate with the 1st orderer
   IFS=', ' read -r -a OORGS <<< "$ORDERER_ORGS"
   initOrdererVars ${OORGS[0]} 1
   ORDERER_PORT_ARGS="-o $ORDERER_HOST:7050 --tls true --cafile $INT_CA_CHAINFILE"

   # Convert PEER_ORGS to an array named PORGS
   IFS=', ' read -r -a PORGS <<< "$PEER_ORGS"
   log "PORGS: $PORGS ..."

   # Create the channel
   createChannel

   # All peers join the channel
   for ORG in $PEER_ORGS; do
      COUNT=1
      while [[ "$COUNT" -le $NUM_PEERS ]]; do
         initPeerVars $ORG $COUNT
         joinChannel
         COUNT=$((COUNT+1))
      done
   done

   # Update the anchor peers
   for ORG in $PEER_ORGS; do
      initPeerVars $ORG 1
      enrollFabricAdmin
      log "Updating anchor peers for $PEER_HOST ..."
      peer channel update -c $CHANNEL_NAME -f $ANCHOR_TX_FILE $ORDERER_PORT_ARGS
   done

   # Install chaincode on the 2nd peer in each org
   for ORG in $PEER_ORGS; do
      initPeerVars $ORG 2
      installChaincode
   done

   # Instantiate chaincode on the 2nd peer of the 2nd org
   makePolicy
   initPeerVars ${PORGS[1]} 2
   enrollFabricAdmin
   log "Instantiating chaincode on $PEER_HOST ..."
   peer chaincode instantiate -C $CHANNEL_NAME -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "$POLICY" $ORDERER_PORT_ARGS

   # Query on chaincode from the 1st peer of the 1st org
   initPeerVars ${PORGS[0]} 1
   enrollFabricUser
   log "Querying chaincode on $PEER_HOST ..."
   chaincodeQuery 100

   # Invoke on chaincode on the 1st peer of the 1st org
   initPeerVars ${PORGS[0]} 1
   enrollFabricUser
   log "Sending invoke transaction to $PEER_HOST ..."
   peer chaincode invoke -C $CHANNEL_NAME -n mycc -c '{"Args":["invoke","a","b","10"]}' $ORDERER_PORT_ARGS

   ## Install chaincode on 1st peer of 2nd org
   initPeerVars ${PORGS[1]} 1
   enrollFabricUser
   installChaincode

   # Query on chaincode on 1st peer of 2nd org
   initPeerVars ${PORGS[1]} 1
   enrollFabricUser
   log "Querying chaincode on $PEER_HOST ..."
   chaincodeQuery 90

   log "Congratulations!  The test completed successfully."

}

# Enroll as a peer admin and create the channel
function createChannel {
   initPeerVars ${PORGS[0]} 1
   enrollFabricAdmin
   log "Creating channel '$CHANNEL_NAME' on $ORDERER_HOST ..."
   peer channel create -c $CHANNEL_NAME -f $CHANNEL_TX_FILE $ORDERER_PORT_ARGS
}

# Enroll as a peer admin and join the channel
function joinChannel {
   enrollFabricAdmin
   set +e
   log "Peer $PEER_HOST joining channel ..."
   COUNT=0
   while true; do
      peer channel join -b $CHANNEL_NAME.block
      if [ $? -eq 0 ]; then
         set -e
         return
      fi
      if [ $COUNT -gt $MAX_RETRY ]; then
         fatal "Peer $PEER_HOST failed to join channel"
      fi
      COUNT=$((COUNT+1))
   done
}

function makePolicy  {
   POLICY="OR \("
   COUNT=0
   for ORG in $PEER_ORGS; do
      if [ $COUNT -ne 0 ]; then
         POLICY="${POLICY},"
      fi
      initOrgVars $ORG
      POLICY="${POLICY}'${ORG_MSP_ID}'"
      COUNT=$((COUNT+1))
   done
   POLICY="${POLICY}\)"
   log "policy: $POLICY"
}

function installChaincode {
   log "Installing chaincode on $PEER_HOST ..."
   peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02
}

set -e

SDIR=$(dirname "$0")
source $SDIR/env.sh

main
