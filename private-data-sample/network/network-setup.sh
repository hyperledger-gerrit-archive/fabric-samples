#!/bin/bash
#
# Copyright Persistent Systems 2018. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#

export IMAGE_TAG=latest
export COMPOSE_PROJECT_NAME=auction
 
COMPOSE_FILE=../../first-network/docker-compose-e2e.yaml
COMPOSE_FILE_COUCH=../../first-network/docker-compose-couch.yaml
COMPOSE_FILE_CLI=./docker-compose-priv-cli.yaml

CHANNEL_NAME="mychannel"
CLI_DELAY=3
LANGUAGE=golang
CLI_TIMEOUT=10
VERBOSE=true


# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  network-setup.sh <mode>"
  echo "    <mode> - one of 'up', 'down'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "This script makes use of network config from first-network sample."
}

function networkStart(){
  CURRENT_DIR=$PWD
  cd ../../first-network/
  ./byfn.sh generate -c $CHANNEL_NAME

  echo "--------- generated crypto material... ---------"
  cd "$CURRENT_DIR"
  echo "--------- CURRENT_DIR is........"
  echo $PWD
  
  docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH up -d 2>&1
  docker-compose -f $COMPOSE_FILE_CLI up -d 2>&1

  # now run the end to end script
  docker exec cli scripts/script.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT $VERBOSE
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Test failed"
    exit 1
  fi

}

function networkDown(){

  CURRENT_DIR=$PWD
  cd ../../first-network/
  ./byfn.sh down -c $CHANNEL_NAME

  cd "$CURRENT_DIR"
  docker-compose -f $COMPOSE_FILE_CLI down --volumes --remove-orphans

  clearContainers
  removeUnwantedImages

}

# Obtain CONTAINER_IDS and remove them
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*.auctioncc.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
# specifically the following images are often left behind:
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*.auctioncc.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}


function replacePrivateKeyForSDK(){
  # sed on MacOSX does not support -i flag with a null extension. We will use
  # 't' for our back-up's extension and delete it at the end of the function
  ARCH=$(uname -s | grep Darwin)
  if [ "$ARCH" == "Darwin" ]; then
    OPTS="-it"
  else
    OPTS="-i"
  fi

  # Copy the template to the file that will be modified to add the private key
  cp ../api/config/network-config-template.yaml ../api/config/network-config.yaml

  # The next steps will replace the template's contents with the
  # actual values of the private key file names for the two CAs.
  CURRENT_DIR=$PWD
  cd ../../first-network/crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/
  #cd ../../first-network/crypto-config/peerOrganizations/org1.example.com/ca/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" ../api/config/network-config.yaml
  #cd ../../first-network/crypto-config/peerOrganizations/org2.example.com/ca/
  cd ../../first-network/crypto-config/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp/keystore/
  PRIV_KEY=$(ls *_sk)
  cd "$CURRENT_DIR"
  sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" ../api/config/network-config.yaml
  # If MacOSX, remove the temporary backup of the docker-compose file
  if [ "$ARCH" == "Darwin" ]; then
    rm ../api/config/network-config.yamlt
  fi


}

# Parse commandline args
MODE=$1
shift

# Determine whether starting, stopping, generating
if [ "$MODE" == "up" ]; then
  EXPMODE="Starting"
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping"
fi


# Announce what was requested
echo "${EXPMODE} for channel '${CHANNEL_NAME}'"

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  networkStart
  replacePrivateKeyForSDK
  
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
else
  printHelp
  exit 1
fi

