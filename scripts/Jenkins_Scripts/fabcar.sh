#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
#

# docker container list
CONTAINER_LIST=(peer0.org1 orderer ca)

MARCH=$(uname -s|tr '[:upper:]' '[:lower:]')
echo "-----------> MARCH" $MARCH
echo "-----------> PROJECT_VERSION:" $PROJECT_VERSION
# Get the latest binaries from nexus2 URL
MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-$PROJECT_VERSION/maven-metadata.xml")
curl -L "$MVN_METADATA" > maven-metadata.xml
RELEASE_TAG=$(cat maven-metadata.xml | grep release)
COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
echo "-----------> COMMIT = $COMMIT"
cd $BASE_FOLDER/fabric-samples || exit
# Download the Binary tar file from nexus2 URL
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-$PROJECT_VERSION/$MARCH-$ARCH.$PROJECT_VERSION-$COMMIT/hyperledger-fabric-$PROJECT_VERSION-$MARCH-$ARCH.$PROJECT_VERSION-$COMMIT.tar.gz | tar xz

if [ $? -ne 0 ]; then
   echo -e "\033[31m FAILED to download binaries" "\033[0m"
   exit 1
fi

cd fabcar || exit
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

logs() {

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

for CONTAINER in ${CONTAINER_LIST[*]}; do
    docker logs $CONTAINER.example.com >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$1.log
    echo
done

# Write couchdb container logs into couchdb.log file
docker logs couchdb >& couchdb.log

}

copy_logs() {

# Call logs function
logs $2 $3

if [ $1 != 0 ]; then
    echo -e "\033[31m $2 test case is FAILED" "\033[0m"
    exit 1
fi
}

LANGUAGES="go javascript typescript"
for LANGUAGE in ${LANGUAGES}; do
    echo -e "\033[32m starting fabcar test (${LANGUAGE})" "\033[0m"
    ./startFabric.sh ${LANGUAGE}
    copy_logs $? fabcar-${LANGUAGE}
    docker ps -aq | xargs docker rm -f 
    docker rmi -f $(docker images -aq dev-*)
    echo -e "\033[32m finished fabcar test (${LANGUAGE})" "\033[0m"
done
