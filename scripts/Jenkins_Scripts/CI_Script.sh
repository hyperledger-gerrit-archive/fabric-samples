#!/bin/bash -e
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# exit on first error

export BASE_FOLDER=$WORKSPACE/gopath/src/github.com/hyperledger
export NEXUS_URL=nexus3.hyperledger.org:10001
export ORG_NAME="hyperledger/fabric"

# Fetch baseimage version
curl -L https://raw.githubusercontent.com/hyperledger/fabric/master/Makefile > Makefile
export BASE_IMAGE_VER=`cat Makefile | grep BASEIMAGE_RELEASE= | cut -d "=" -f2`
echo "-----------> BASE_IMAGE_VER" $BASE_IMAGE_VER
export OS_VER=$(dpkg --print-architecture)
echo "-----------> OS_VER" $OS_VER
export BASE_IMAGE_TAG=$OS_VER-$BASE_IMAGE_VER

# Fetch Go Version from fabric ci.properties file
curl -L https://raw.githubusercontent.com/hyperledger/fabric/master/ci.properties > ci.properties
export GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
echo "-----------> GO_VER" $GO_VER

# Published stable version from nexus
export STABLE_TAG=$OS_VER-$PROJECT_VERSION
echo "-----------> STABLE_TAG" $STABLE_TAG

Parse_Arguments() {
      while [ $# -gt 0 ]; do
              case $1 in
                      --env_Info)
                            env_Info
                            ;;
                      --SetGopath)
                            setGopath
                            ;;
                      --pull_Docker_Images)
                            pull_Docker_Images
                            ;;
                      --pull_Fabric_CA_Images)
                            pull_Fabric_CA_Images
                            ;;
                      --clean_Environment)
                            clean_Environment
                            ;;
		      --byfn_eyfn_Tests)
                            byfn_eyfn_Tests
                            ;;
                      --pull_Thirdparty_Images)
                            pull_Thirdparty_Images
                            ;;
              esac
              shift
      done
}

clean_Environment() {

echo "-----------> Clean Docker Containers & Images, unused/lefover build artifacts"
function clearContainers () {
        CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" ] || [ "$CONTAINER_IDS" = " " ]; then
                echo "---- No containers available for deletion ----"
        else
                docker rm -f $CONTAINER_IDS || true
                docker ps -a
        fi
}

function removeUnwantedImages() {
        DOCKER_IMAGES_SNAPSHOTS=$(docker images | grep snapshot | grep -v grep | awk '{print $1":" $2}')

        if [ -z "$DOCKER_IMAGES_SNAPSHOTS" ] || [ "$DOCKER_IMAGES_SNAPSHOTS" = " " ]; then
                echo "---- No snapshot images available for deletion ----"
        else
	        docker rmi -f $DOCKER_IMAGES_SNAPSHOTS || true
	fi
        DOCKER_IMAGE_IDS=$(docker images | grep -v 'base*\|couchdb\|kafka\|zookeeper\|cello' | awk '{print $3}')

        if [ -z "$DOCKER_IMAGE_IDS" ] || [ "$DOCKER_IMAGE_IDS" = " " ]; then
                echo "---- No images available for deletion ----"
        else
                docker rmi -f $DOCKER_IMAGE_IDS || true
                docker images
        fi
}

# remove tmp/hfc and hfc-key-store data
rm -rf /home/jenkins/.nvm /home/jenkins/npm /tmp/fabric-shim /tmp/hfc* /tmp/npm* /home/jenkins/kvsTemp /home/jenkins/.hfc-key-store

rm -rf /var/hyperledger/*

rm -rf gopath/src/github.com/hyperledger/fabric-ca/vendor/github.com/cloudflare/cfssl/vendor/github.com/cloudflare/cfssl_trust/ca-bundle || true
# yamllint disable-line rule:line-length
rm -rf gopath/src/github.com/hyperledger/fabric-ca/vendor/github.com/cloudflare/cfssl/vendor/github.com/cloudflare/cfssl_trust/intermediate_ca || true

clearContainers
removeUnwantedImages
}

env_Info() {
	# This function prints system info

	#### Build Env INFO
	echo "-----------> Build Env INFO"
	# Output all information about the Jenkins environment
	uname -a
	cat /etc/*-release
	env
	gcc --version
	docker version
	docker info
	docker-compose version
	pgrep -a docker
}

# Pull Thirdparty Docker images (Kafka, couchdb, zookeeper)
pull_Thirdparty_Images() {
            for IMAGES in kafka couchdb zookeeper; do
                 echo "-----------> Pull $IMAGES image"
                 echo
                 docker pull $ORG_NAME-$IMAGES:$BASE_IMAGE_TAG > /dev/null 2>&1
                 if [ $? -ne 0 ]; then
                       echo -e "\033[31m FAILED to pull docker images" "\033[0m"
                       exit 1
                 fi
                 docker tag $ORG_NAME-$IMAGES:$BASE_IMAGE_TAG $ORG_NAME-$IMAGES
            done
                 echo
                 docker images | grep hyperledger/fabric
}
# pull fabric images from nexus
pull_Docker_Images() {
            pull_Fabric_CA_Image
            for IMAGES in peer orderer tools ccenv; do
                 echo "-----------> pull $IMAGES image"
                 echo
                 docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG > /dev/null 2>&1
                 if [ $? -ne 0 ]; then
                       echo -e "\033[31m FAILED to pull docker images" "\033[0m"
                       exit 1
                 fi
                 docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES
                 docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES:$STABLE_TAG
                 docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
            done
                 echo
                 docker images | grep hyperledger/fabric
}
# pull fabric-ca images from nexus
pull_Fabric_CA_Image() {
            for IMAGES in ca ca-peer ca-orderer ca-tools; do
                 echo "-----------> pull $IMAGES image"
                 echo
                 docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG > /dev/null 2>&1
                 if [ $? -ne 0 ]; then
                       echo -e "\033[31m FAILED to pull docker images" "\033[0m"
                       exit 1
                 fi
                 docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES
	         docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES:$STABLE_TAG
                 docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
            done
                 echo
                 docker images | grep hyperledger/fabric-ca
}
# run byfn,eyfn tests
byfn_eyfn_Tests() {
	echo
	echo "-----------> Execute Byfn and Eyfn Tests"
	./byfn_eyfn.sh
}
Parse_Arguments $@
