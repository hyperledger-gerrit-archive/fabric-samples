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

docker network inspect adv-commercialpaper-net &>/dev/null || docker network create adv-commercialpaper-net

docker-compose -f docker-compose.yml up -d

# wait for peer to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
# Check MagnetoCorp command
export FABRIC_START_TIMEOUT=30
for i in $(seq 1 ${FABRIC_START_TIMEOUT})
do
    # This command only works if the peer is up and running
    if docker exec peer3ecobank peer channel list > /dev/null 2>&1
    then
        # Peer now available
        break
    else
        # Sleep and try again
        sleep 1
    fi
done
echo Hyperledger Fabric Fedbank Peer checked in $i seconds

echo Script completed successfully.