#!/bin/bash -e

# exit on first error

export BASE_FOLDER=$WORKSPACE/gopath/src/github.com/hyperledger

Parse_Arguments() {
      while [ $# -gt 0 ]; do
              case $1 in
                      --env_Info)
                            env_Info
                            ;;
                      --clone_SetGopath)
                            clone_SetGopath
                            ;;
                      --build_Fabric_Images)
                            build_Fabric_Images
                            ;;
                      --build_Fabric_CA_Image)
                            build_Fabric_CA_Image
                            ;;
                      --cleanEnvironment)
                            cleanEnvironment
                            ;;
		      --byfn_eyfn_Tests)
                            byfn_eyfn_Tests
                            ;;
              esac
              shift
      done
}

cleanEnvironment() {

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

clone_SetGopath() {
        echo "Info: -------> Clone $1 repository and set GOPATH"
	echo
        cd ${BASE_FOLDER} && git clone --depth=1 git://cloud.hyperledger.org/mirror/$1 -b master
        cd ${BASE_FOLDER}/$1 && git checkout master
	GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
        OS_VER=$(dpkg --print-architecture)
	export GOPATH=$WORKSPACE/gopath
	export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
        export PATH=$GOROOT/bin:$GOPATH/bin:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:~/npm/bin:/home/jenkins/.nvm/versions/node/v6.9.5/bin:/home/jenkins/.nvm/versions/node/v8.9.4/bin:$PATH
        export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
	export PATH=$GOROOT/bin:$PATH
        echo "Info: ------->  GO_VER" $GO_VER
}

build_Fabric_Images() {
	echo
        clone_SetGopath fabric
        for IMAGES in docker release-clean release; do
               make $IMAGES
	           if [ $? != 0 ]; then
                       echo "Error: -------> make $IMAGES failed"
                       exit 1
                   fi
		       echo "Info: -------> make $IMAGES build successfully"
        done
	       echo
	       echo "Info: -------> List all docker images"
	       make docker-list
	           if [ $? != 0 ]; then
                       echo "Error: -------> make docker-list failed"
                       exit 1
                   fi
		       echo "Info: -------> make docker-list successfull"
	       echo
}

build_Fabric_CA_Image() {
	echo
        clone_SetGopath fabric-ca
	for IMAGES in docker-fabric-ca; do
             make $IMAGES
                if [ $? != 0 ]; then
                     echo "Error: -------> make $IMAGES failed"
		     exit 1
                fi
		     echo "Info: -------> make $IMAGES build successfully"
         done
	     echo
	     echo "Info: -------> List all fabric-ca docker images"
             docker images | grep hyperledger/fabric-ca
}

byfn_eyfn_Tests() {
	echo
	echo "-------> Execute Byfn and Eyfn Tests"
	./byfn_eyfn.sh
}
