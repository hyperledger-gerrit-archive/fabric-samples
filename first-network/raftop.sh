#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script extends the Hyperledger Fabric Build Your First Network with a Raft ordering service
# by demonstrating how to create a channel with a subset of consenters.
#

# prepending $PWD/../bin to PATH to ensure we are picking up the correct binaries
# this may be commented out to resolve installed version of tools if desired
export PATH=${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

# Print the usage message
function printHelp () {
  echo "Usage: "
  echo "  raftop.sh up|down|generate [-c <channel name>] [-t <timeout>] [-d <delay>] [-f <docker-compose-file>] [-l <language>] [-v]"
  echo "  raftop.sh -h|--help (print this message)"
  echo "    <mode> - one of 'up', 'down' or 'generate'"
  echo "      - 'up' - apply the channel creation tx and run the rest of the script"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'generate' - generate required channel create block and signs it"
  echo "    -c <channel name> - channel name to use (defaults to \"mychannel2\")"
  echo "    -t <timeout> - CLI timeout duration in seconds (defaults to 10)"
  echo "    -d <delay> - delay duration in seconds (defaults to 3)"
  echo "    -f <docker-compose-file> - specify which docker-compose file use (defaults to docker-compose-cli.yaml)"
  echo "    -l <language> - the chaincode language: golang (default) or node"
  echo "    -v - verbose mode"
  echo
  echo "Typically, one would first generate the required certificates and "
  echo "genesis block, then bring up the network using BYFN script. e.g.:"
  echo
  echo "    byfn.sh -o etcdraft"
  echo
  echo "Taking all defaults:"
  echo "	raftop.sh generate"
  echo "	raftop.sh up"
  echo "	raftop.sh down"
}

# Ask user for confirmation to proceed
function askProceed () {
  read -p "Continue? [Y/n] " ans
  case "$ans" in
    y|Y|"" )
      echo "proceeding ..."
    ;;
    n|N )
      echo "exiting..."
      exit 1
    ;;
    * )
      echo "invalid response"
      askProceed
    ;;
  esac
}

# Generate the needed certificates, the genesis block and start the network.
function networkUp () {
  # generate artifacts if they don't exist
  if [ ! -f "$CREATE_CHANNEL_FILE" ]; then
    generateChannelArtifacts
  fi

  # now run the end to end script
  docker exec cli scripts/raft_script.sh "$CHANNEL_NAME" "$CREATE_CHANNEL_FILE" "$CLI_DELAY" "$LANGUAGE" "$CLI_TIMEOUT" "$VERBOSE"
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Test failed"
    exit 1
  fi
}

# Tear down running network
function networkDown() {
  echo "Please use 'byfn.sh down' in order to remove the network"
}

# Generate channel configuration transaction
function generateChannelArtifacts() {
  echo
  echo "##################################################################"
  echo "### Generating channel configuration transaction 'channel2.tx' ###"
  echo "##################################################################"
  set -x
  configtxgen -channelCreateTxBaseProfile SampleMultiNodeEtcdRaft -profile TwoOrgsChannelSubset -outputCreateChannelTx "$CREATE_CHANNEL_FILE" -channelID $CHANNEL_NAME
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  docker exec cli ./scripts/raft_sign_config.sh "$CHANNEL_NAME" "$CREATE_CHANNEL_FILE"
}

# Checks that the consensus type is etcdraft
function checkEtcdRaft() {
    local genesis_file
    local res
    genesis_file="./channel-artifacts/genesis.block"
    configtxlator proto_decode --type=common.Block --input="$genesis_file" | grep -q 'etcdraft'
    res=$?
    return $res
}

######### Start here ###########

# If BYFN wasn't run abort
if [ ! -d crypto-config ] || ( ! checkEtcdRaft ); then
  echo
  echo "ERROR: Please, run 'byfn.sh up -o etcdraft' first."
  echo
  exit 1
fi

# Obtain the OS and Architecture string that will be used to select the correct
# native binaries for your platform
OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
#default for delay
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel2"
#
CREATE_CHANNEL_FILE="./channel-artifacts/channel2.tx"
# use this as the default docker-compose yaml definition
COMPOSE_FILE=docker-compose-cli.yaml
#
COMPOSE_FILE_COUCH=docker-compose-couch.yaml
# use this as the default docker-compose yaml definition
COMPOSE_FILE_ORG3=docker-compose-org3.yaml
#
COMPOSE_FILE_COUCH_ORG3=docker-compose-couch-org3.yaml
# kafka and zookeeper compose file
COMPOSE_FILE_KAFKA=docker-compose-kafka.yaml
# two additional etcd/raft orderers
COMPOSE_FILE_RAFT2=docker-compose-etcdraft2.yaml
# use golang as the default language for chaincode
LANGUAGE=golang

# Parse commandline args
if [ "$1" = "-m" ];then	# supports old usage, muscle memory is powerful!
    shift
fi
MODE=$1;shift
# Determine whether starting, stopping or generating for announce
if [ "$MODE" == "up" ]; then
  EXPMODE="Starting"
elif [ "$MODE" == "down" ]; then
  EXPMODE="Stopping"
elif [ "$MODE" == "generate" ]; then
  EXPMODE="Generating channel creation tx for"
else
  printHelp
  exit 1
fi
while getopts "h?c:t:d:f:l:v" opt; do
  case "$opt" in
    h|\?)
      printHelp
      exit 0
    ;;
    c)  CHANNEL_NAME=$OPTARG
    ;;
    t)  CLI_TIMEOUT=$OPTARG
    ;;
    d)  CLI_DELAY=$OPTARG
    ;;
    f)  COMPOSE_FILE=$OPTARG
    ;;
    l)  LANGUAGE=$OPTARG
    ;;
    v)  VERBOSE=true
    ;;
  esac
done

# Announce what was requested
echo "${EXPMODE} channel '${CHANNEL_NAME}' and CLI timeout of '${CLI_TIMEOUT}' seconds and CLI delay of '${CLI_DELAY}' seconds"
# ask for confirmation to proceed
askProceed

#Create the network using docker compose
if [ "${MODE}" == "up" ]; then
  networkUp
elif [ "${MODE}" == "down" ]; then ## Clear the network
  networkDown
elif [ "${MODE}" == "generate" ]; then ## Generate Artifacts
  generateChannelArtifacts
else
  printHelp
  exit 1
fi
