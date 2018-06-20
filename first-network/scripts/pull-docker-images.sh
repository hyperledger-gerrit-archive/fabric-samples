#!/bin/bash -e
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

############################################
# Pull "stable" docker images from nexus3
# Tag it as $ARCH-$VERSION (BASE_VERSION)
#############################################

export ORG_NAME=hyperledger/fabric
export NEXUS_URL=nexus3.hyperledger.org:10001
export VERSION=1.2.0
export SUFFIX=stable
export OS_VER=$(uname -s | tr '[:upper:]' '[:lower:]')
echo "---------> OS_VER" $OS_VER
export ARCH=$(go env GOARCH)
if [ "$ARCH" = "amd64" ]; then
	ARCH=amd64
else
	ARCH=$(uname -m)
fi

for IMAGES in peer orderer ccenv tools ca; do
	docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$VERSION-$SUFFIX
	docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$VERSION-$SUFFIX $ORG_NAME-$IMAGES:$ARCH-$VERSION
	docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$VERSION-$SUFFIX $ORG_NAME-$IMAGES:latest
	docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$VERSION-$SUFFIX
done

MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/maven-metadata.xml")
curl -L "$MVN_METADATA" >maven-metadata.xml
RELEASE_TAG=$(cat maven-metadata.xml | grep release)
export COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
echo "---------> COMMIT:" $COMMIT
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/$OS_VER-$ARCH.$VERSION-$SUFFIX-$COMMIT/hyperledger-fabric-stable-$OS_VER-$ARCH.$VERSION-$SUFFIX-$COMMIT.tar.gz | tar xz
echo "---------> Working DIR " $PWD
ls -l bin/
