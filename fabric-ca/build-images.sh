#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#
# This script sets up to run the sample.
#

set -e

SDIR=$(dirname "$0")
source $SDIR/scripts/env.sh

# Delete docker containers
dockerContainers=$(docker ps -aq)
if [ "$dockerContainers" != "" ]; then
   log "Deleting existing docker containers ..."
   docker rm -f $dockerContainers > /dev/null
fi

# Remove chaincode docker images
chaincodeImages=`docker images | grep "^dev-peer" | awk '{print $3}'`
if [ "$chaincodeImages" != "" ]; then
   log "Removing chaincode docker images ..."
   docker rmi $chaincodeImages > /dev/null
fi

# Perform docker clean for fabric-ca
log "Cleaning fabric-ca docker images ..."
cd $GOPATH/src/github.com/hyperledger/fabric-ca
make docker-clean

# Perform docker clean for fabric and rebuild
log "Cleaning and rebuilding fabric docker images ..."
cd $GOPATH/src/github.com/hyperledger/fabric
make docker-clean docker

# Perform docker clean for fabric and rebuild against latest fabric images just built
log "Rebuilding fabric-ca docker images ..."
export USE_LATEST_FABRIC=true
cd $GOPATH/src/github.com/hyperledger/fabric-ca
make docker

log "Setup completed successfully.  You may run the tests multiple times by running start.sh."
