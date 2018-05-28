#!/bin/bash -e

# exit on first error

export BASE_FOLDER=$WORKSPACE/gopath/src/github.com/hyperledger
export PROJECT_VERSION=1.2.0-stable
export NEXUS_URL=nexus3.hyperledger.org:10001
export ORG_NAME="hyperledger/fabric"
export NODE_VER=8.9.4

Parse_Arguments() {
      while [ $# -gt 0 ]; do
              case $1 in
                      --env_Info)
                            env_Info
                            ;;
                      --SetGopath)
                            setGopath
                            ;;
                      --build_Fabric_Images)
                            build_Fabric_Images
                            ;;
                      --build_Fabric_CA_Image)
                            build_Fabric_CA_Image
                            ;;
                      --clean_Environment)
                            clean_Environment
                            ;;
		      --byfn_eyfn_Tests)
                            byfn_eyfn_Tests
                            ;;
              esac
              shift
      done
}

clean_Environment() {

echo "Info: -------> Clean Docker Containers & Images, unused/lefover build artifacts"
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
	echo "Info: -------> Build Env INFO"
	# Output all information about the Jenkins environment
	uname -a
	cat /etc/*-release
	env
	gcc --version
	docker version
	docker info
	docker-compose version
	pgrep -a docker
	docker images
	docker ps -a
}

setGopath() {
        echo "-----------> set GOPATH"
	echo
	curl -L https://raw.githubusercontent.com/hyperledger/$1/master/ci.properties > ci.properties
	GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
        OS_VER=$(dpkg --print-architecture)
	export GOPATH=$WORKSPACE/gopath
	export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
        export PATH=$GOROOT/bin:$GOPATH/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:~/npm/bin:/home/jenkins/.nvm/versions/node/v6.9.5/bin:/home/jenkins/.nvm/versions/node/v$NODE_VER/bin:$PATH
        export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
	export PATH=$GOROOT/bin:$PATH
        export ARCH=$(go env GOARCH)
        export STABLE_TAG=$ARCH-$PROJECT_VERSION
        echo "-----------> STABLE_TAG:" $STABLE_TAG
        echo "-----------> GO_VER" $GO_VER
}

build_Fabric_Images() {
        setGopath fabric # set gopath
            for IMAGES in peer orderer tools ccenv; do
                 echo "----------> IMAGES:" $IMAGES
                 echo
                 docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
                 docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES
                 docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES:$STABLE_TAG
                 docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
            done
                 echo
                 docker images | grep hyperledger/fabric
}

build_Fabric_CA_Image() {
	echo
        setGopath fabric-ca
            for IMAGES in ca ca-peer ca-orderer ca-tools; do
                 echo "----------> $IMAGES"
                 echo
                 docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
                 docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES
	         docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG $ORG_NAME-$IMAGES:$STABLE_TAG
                 docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
            done
                 echo
                 docker images | grep hyperledger/fabric-ca
}

byfn_eyfn_Tests() {
	echo
	echo "----------> Execute Byfn and Eyfn Tests"
	./byfn_eyfn.sh
}
Parse_Arguments $@
