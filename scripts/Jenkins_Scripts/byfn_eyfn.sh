#!/bin/bash

ARCH=$(dpkg --print-architecture)
# docker container list
CONTAINER_LIST=(peer0.org1 peer1.org1 peer0.org2 peer1.org2 peer0.org3 peer1.org3 orderer)
COUCHDB_CONTAINER_LIST=(couchdb0 couchdb1 couchdb2 couchdb3 couchdb4 couchdb5)

MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/maven-metadata.xml")
curl -L "$MVN_METADATA" > maven-metadata.xml
RELEASE_TAG=$(cat maven-metadata.xml | grep release)
COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
VERSION=1.2.0
echo "------> BASE_VERSION = $VERSION"
cd $BASE_FOLDER/fabric-samples || exit
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/linux-$ARCH.$VERSION-stable-$COMMIT/hyperledger-fabric-stable-linux-$ARCH.$VERSION-stable-$COMMIT.tar.gz | tar xz
# copy /bin directory to fabric-samples

cd first-network || exit

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml

export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

artifacts() {

    echo "---> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p "$WORKSPACE/archives"
    mv "$WORKSPACE/Docker_Container_Logs" $WORKSPACE/archives/
}

# Capture docker logs of each container
logs() {

for CONTAINER in ${CONTAINER_LIST[*]}; do
    docker logs $CONTAINER.example.com >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$1.log
    echo
done

if [ ! -z $2 ]; then

    for CONTAINER in ${COUCHDB_CONTAINER_LIST[*]}; do
        docker logs $CONTAINER >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$1.log
        echo
    done
fi
}

copy_logs() {

# Call logs function
logs $2 $3

if [ $1 != 0 ]; then
    artifacts
    exit 1
fi
}

        echo "############## BYFN,EYFN DEFAULT CHANNEL TEST ###################"
        echo "#################################################################"

        echo y | ./byfn.sh -m down
        echo y | ./byfn.sh -m up -t 60
        copy_logs $? default-channel
        echo y | ./eyfn.sh -m up -t 60
        copy_logs $? default-channel
        echo y | ./eyfn.sh -m down
        echo
        echo "############## BYFN,EYFN CUSTOM CHANNEL TEST ############"
        echo "#########################################################"

        echo y | ./byfn.sh -m up -c custom-channel -t 60
        copy_logs $? custom-channel
        echo y | ./eyfn.sh -m up -c custom-channel -t 60
        copy_logs $? custom-channel
        echo y | ./eyfn.sh -m down
        echo
        echo "############### BYFN,EYFN CUSTOM CHANNEL WITH COUCHDB TEST ##############"
        echo "#########################################################################"

        echo y | ./byfn.sh -m up -c custom-channel-couchdb -s couchdb -t 60
        copy_logs $? custom-channel-couch couchdb
        echo y | ./eyfn.sh -m up -c custom-channel-couchdb -s couchdb -t 60
        copy_logs $? custom-channel-couch couchdb
        echo y | ./eyfn.sh -m down
        echo
        echo "############### BYFN,EYFN WITH NODE Chaincode. TEST ################"
        echo "####################################################################"

        echo y | ./byfn.sh -m up -l node -t 60
        copy_logs $? default-channel-node
        echo y | ./eyfn.sh -m up -l node -t 60
        copy_logs $? default-channel-node
        echo y | ./eyfn.sh -m down

        echo "############### FABRIC-CA SAMPLES TEST ########################"
        echo "###############################################################"
        cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/fabric-ca || exit
        ./start.sh && ./stop.sh
