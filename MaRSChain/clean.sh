#!/bin/bash

# remove containers
CONTAINER_IDS=$(docker ps -aq)
docker rm -f $CONTAINER_IDS

# remove chaincode images
DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
docker rmi -f $DOCKER_IMAGE_IDS

# clean up certifcate stores
rm -rf /tmp/fabric-client-kv-*
rm -rf fabric-client-kv-*

