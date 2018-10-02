#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run in the cli container as the third
# step of the EYFN tutorial. It installs the chaincode as version 2.0
# on peer0.org1 and peer0.org2, and uprage the chaincode on the
# channel to version 2.0, thus completing the addition of org3 to the
# network previously setup in the BYFN tutorial.
#

echo
echo "========= Finish adding Org3 to your first network ========= "
echo
CHANNEL_NAME="$1"
DELAY="$2"
CC_SRC_LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${CC_SRC_LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
CC_SRC_LANGUAGE=`echo "$CC_SRC_LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5

if [ "$CC_SRC_LANGUAGE" = "golang" ]; then
	CC_RUNTIME_LANGUAGE=golang
	CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
elif [ "$CC_SRC_LANGUAGE" = "javascript" ]; then
	CC_RUNTIME_LANGUAGE=node # chaincode runtime language is node.js
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/javascript/"
elif [ "$CC_SRC_LANGUAGE" = "java" ]; then
	CC_RUNTIME_LANGUAGE=java
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/java/"
else
	echo The chaincode language ${CC_SRC_LANGUAGE} is not supported by this script
	echo Supported chaincode languages are: golang, javascript, java
	exit 1
fi

# import utils
. scripts/utils.sh

echo "===================== Installing chaincode 2.0 on peer0.org1 ===================== "
installChaincode 0 1 2.0
echo "===================== Installing chaincode 2.0 on peer0.org2 ===================== "
installChaincode 0 2 2.0

echo "===================== Upgrading chaincode on peer0.org1 ===================== "
upgradeChaincode 0 1

echo
echo "========= Finished adding Org3 to your first network! ========= "
echo

exit 0
