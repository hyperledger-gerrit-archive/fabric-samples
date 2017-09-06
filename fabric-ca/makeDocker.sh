#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#
# This script builds the docker containers needed to run this sample
# See the main function below for which DC (docker-compose) files are created.
#

SDIR=$(dirname "$0")
source $SDIR/scripts/env.sh

function main {
   {
   writeHeader
   writeRootFabricCA
   writeIntermediateFabricCA
   writeSetupFabric
   writeStartFabric
   writeRunFabric
   } > $SDIR/docker-compose.yml
   echo "Created docker-compose.yml"
}

# Write services for the root fabric CA servers
function writeRootFabricCA {
   for ORG in $ORGS; do
      initOrgVars $ORG
      writeRootCA
   done
}

# Write services for the intermediate fabric CA servers
function writeIntermediateFabricCA {
   for ORG in $ORGS; do
      initOrgVars $ORG
      writeIntermediateCA
   done
}

# Write a service to setup the fabric artifacts (e.g. genesis block, etc)
function writeSetupFabric {
   echo "  setup:
    container_name: setup
    image: hyperledger/fabric-ca-tools
    command: /bin/bash -c '/scripts/setup-fabric.sh 2>&1 | tee /$DATA/logs/setup.log; sleep 99999'
    volumes:
      - ./scripts:/scripts
      - ./$DATA:/$DATA
    networks:
      - $NETWORK
    depends_on:"
   for ORG in $ORGS; do
      initOrgVars $ORG
      echo "      - $INT_CA_NAME"
   done
   echo ""
}

# Write services for fabric orderer and peer containers
function writeStartFabric {
   for ORG in $ORDERER_ORGS; do
      COUNT=1
      while [[ "$COUNT" -le $NUM_ORDERERS ]]; do
         initOrdererVars $ORG $COUNT
         writeOrderer
         COUNT=$((COUNT+1))
      done
   done
   for ORG in $PEER_ORGS; do
      COUNT=1
      while [[ "$COUNT" -le $NUM_PEERS ]]; do
         initPeerVars $ORG $COUNT
         writePeer
         COUNT=$((COUNT+1))
      done
   done
}

# Write a service to run a fabric test including creating a channel,
# installing chaincode, invoking and querying
function writeRunFabric {
   echo "  run:
    container_name: run
    image: hyperledger/fabric-ca-tools
    command: /bin/bash -c 'sleep 3;/scripts/run-fabric.sh 2>&1 | tee /$DATA/logs/run.log; sleep 99999'
    volumes:
      - ./scripts:/scripts
      - ./$DATA:/$DATA
      - ./../chaincode/:/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go
    networks:
      - $NETWORK
    depends_on:"
   for ORG in $ORDERER_ORGS; do
      COUNT=1
      while [[ "$COUNT" -le $NUM_ORDERERS ]]; do
         initOrdererVars $ORG $COUNT
         echo "      - $ORDERER_NAME"
         COUNT=$((COUNT+1))
      done
   done
   for ORG in $PEER_ORGS; do
      COUNT=1
      while [[ "$COUNT" -le $NUM_PEERS ]]; do
         initPeerVars $ORG $COUNT
         echo "      - $PEER_NAME"
         COUNT=$((COUNT+1))
      done
   done
}

function writeRootCA {
   echo "  $ROOT_CA_NAME:
    container_name: $ROOT_CA_NAME
    image: hyperledger/fabric-ca
    command: /bin/bash -c '/scripts/start-root-ca.sh $ORG 2>&1 | tee /$DATA/logs/${ROOT_CA_NAME}.log'
    volumes:
      - ./scripts:/scripts
      - ./$DATA:/$DATA
    networks:
      - $NETWORK
"
}

function writeIntermediateCA {
   echo "  $INT_CA_NAME:
    container_name: $INT_CA_NAME
    image: hyperledger/fabric-ca
    command: /bin/bash -c '/scripts/start-intermediate-ca.sh $ORG 2>&1 | tee /$DATA/logs/${INT_CA_NAME}.log'
    volumes:
      - ./scripts:/scripts
      - ./$DATA:/$DATA
    networks:
      - $NETWORK
    depends_on:
      - $ROOT_CA_NAME
"
}

function writeOrderer {
   echo "  $ORDERER_NAME:
    container_name: $ORDERER_NAME
    image: hyperledger/fabric-ca-orderer
    command: /bin/bash -c '/scripts/start-orderer.sh $ORG $COUNT 2>&1 | tee /$DATA/logs/${ORDERER_NAME}.log'
    volumes:
      - ./scripts:/scripts
      - ./$DATA:/$DATA
    networks:
      - $NETWORK
    depends_on:
      - setup
"
}

function writePeer {
   echo "  $PEER_NAME:
    container_name: $PEER_NAME
    image: hyperledger/fabric-ca-peer
    command: /bin/bash -c '/scripts/start-peer.sh $ORG $COUNT 2>&1 | tee /$DATA/logs/${PEER_NAME}.log'
    volumes:
      - ./scripts:/scripts
      - ./$DATA:/$DATA
      - /var/run:/host/var/run
    networks:
      - $NETWORK
    depends_on:
      - setup
"
}

function writeHeader {
   echo "version: '2'

networks:
  $NETWORK:

services:
"
}

main
