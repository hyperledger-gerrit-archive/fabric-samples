#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

# configtxgen -profile PapernetChannel -outputCreateChannelTx ./configtx/papernet-channel.tx -channelID papernet

docker network inspect adv-commercialpaper-net &>/dev/null || docker network create adv-commercialpaper-net

docker-compose -f docker-compose.yml up -d

# wait for command line to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
# Check MagnetoCorp command
export FABRIC_START_TIMEOUT=30
for i in $(seq 1 ${FABRIC_START_TIMEOUT})
do
    # This command only works if the peer is up and running
    if docker exec cli5fedbank ls > /dev/null 2>&1
    then
        # Command line now available
        break
    else
        # Sleep and try again
        sleep 1
    fi
done
echo Hyperledger Fabric ecobank cli checked in $i seconds

# If the papernet channel doesn't exist, then pull genesis block and join channel
if ! docker exec cli5fedbank peer channel getinfo -c papernet
then
    docker exec cli5fedbank peer channel fetch 0 -o orderer1.digibank.example.com:7050 -c papernet papernet.block
    docker exec cli5fedbank peer channel join -b papernet.block
fi

echo Script completed successfully.