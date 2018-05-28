#!/bin/bash

ARCH=$(dpkg --print-architecture)
echo "--------> ARCH" $ARCH
MARCH=$(uname -s|tr '[:upper:]' '[:lower:]')
echo "--------> MARCH" $MARCH
BASE_FOLDER=$GOPATH/src/github.com/hyperledger
MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/maven-metadata.xml")
curl -L "$MVN_METADATA" > maven-metadata.xml
RELEASE_TAG=$(cat maven-metadata.xml | grep release)
COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
VERSION=1.2.0
echo "------> BASE_VERSION = $VERSION"
cd $BASE_FOLDER/fabric-samples || exit
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/$MARCH-$ARCH.$VERSION-stable-$COMMIT/hyperledger-fabric-stable-$MARCH-$ARCH.$VERSION-stable-$COMMIT.tar.gz | tar xz

cd first-network || exit
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

err_Check() {
if [ $1 != 0 ]; then
    echo "-----------> $2 test case failed"
    exit 1
fi
}

 echo "############## BYFN,EYFN DEFAULT CHANNEL TEST ###################"
 echo "#################################################################"
 echo y | ./byfn.sh -m down
 echo y | ./byfn.sh -m p -t 60
 err_Check $? default-channel
 echo y | ./eyfn.sh -m up -t 60
 err_Check $? default-channel
 echo y | ./eyfn.sh -m down
 echo

 echo "############### BYFN,EYFN CUSTOM CHANNEL WITH COUCHDB TEST ##############"
 echo "#########################################################################"
 echo y | ./byfn.sh -m up -c custom-channel-couchdb -s couchdb -t 60
 err_check $? custom-channel-couch couchdb
 echo y | ./eyfn.sh -m up -c custom-channel-couchdb -s couchdb -t 60
 err_check $? custom-channel-couch
 echo y | ./eyfn.sh -m down
 echo

 echo "############### BYFN,EYFN WITH NODE Chaincode. TEST ################"
 echo "####################################################################"
 echo y | ./byfn.sh -m up -l node -t 60
 err_check $? default-channel-node
 echo y | ./eyfn.sh -m up -l node -t 60
 err_check $? default-channel-node
 echo y | ./eyfn.sh -m down

 echo "############### FABRIC-CA SAMPLES TEST ########################"
 echo "###############################################################"
 cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/fabric-ca
 ./start.sh
 err_Check $? fabric-ca
 ./stop.sh
