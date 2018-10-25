#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

ARCH=$(dpkg --print-architecture)
echo "-----------> ARCH" $ARCH
MARCH=$(uname -s|tr '[:upper:]' '[:lower:]')
echo "-----------> MARCH" $MARCH
cd $BASE_FOLDER/fabric-samples || exit
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/$MARCH-$ARCH-$VERSION/hyperledger-fabric-$MARCH-$ARCH-$VERSION.tar.gz | tar xz

cd first-network || exit
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

err_Check() {
if [ $1 != 0 ]; then
    echo -e "\033[31m FAILED: -------> $2 test case failed" "\033[0m"
    exit 1
fi
}

 echo "############## BYFN,EYFN DEFAULT CHANNEL TEST ###################"
 echo "#################################################################"
 echo y | ./byfn.sh -m down
 echo y | ./byfn.sh -m up -t 60
 err_Check $? default-channel
 echo y | ./eyfn.sh -m up -t 60
 err_Check $? default-channel
 echo y | ./eyfn.sh -m down
 echo

 echo "############### BYFN,EYFN CUSTOM CHANNEL WITH COUCHDB TEST ##############"
 echo "#########################################################################"
 echo y | ./byfn.sh -m up -c custom-channel-couchdb -s couchdb -t 75 -d 15
 err_Check $? custom-channel-couch couchdb
 echo y | ./eyfn.sh -m up -c custom-channel-couchdb -s couchdb -t 75 -d 15
 err_Check $? custom-channel-couch
 echo y | ./eyfn.sh -m down
 echo

 echo "############### BYFN,EYFN WITH NODE Chaincode. TEST ################"
 echo "####################################################################"
 echo y | ./byfn.sh -m up -l node -t 60
 err_Check $? default-channel-node
 echo y | ./eyfn.sh -m up -l node -t 60
 err_Check $? default-channel-node
 echo y | ./eyfn.sh -m down

 echo "############### FABRIC-CA SAMPLES TEST ########################"
 echo "###############################################################"
 cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/fabric-ca
 ./start.sh
 err_Check $? fabric-ca
 ./stop.sh
