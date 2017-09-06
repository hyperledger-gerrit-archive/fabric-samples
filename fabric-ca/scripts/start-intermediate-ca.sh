#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

if [ $# -ne 1 ]; then
   echo "Usage: start-int-ca.sh <ORG>"
   exit 1
fi

source $(dirname "$0")/env.sh
initOrgVars $1

# Initialize the intermediate CA
export FABRIC_CA_SERVER_HOME=/etc/hyperledger/fabric-ca
export FABRIC_CA_SERVER_CA_NAME=$INT_CA_NAME
export FABRIC_CA_SERVER_INTERMEDIATE_TLS_CERTFILES=$ROOT_CA_CERTFILE
export FABRIC_CA_SERVER_CSR_HOSTS=$INT_CA_HOST
export FABRIC_CA_SERVER_TLS_ENABLED=true
export FABRIC_CA_SERVER_DEBUG=true
PURL=https://$ROOT_CA_ADMIN_USER_PASS@$ROOT_CA_HOST:7054
fabric-ca-server init -b $INT_CA_ADMIN_USER_PASS -u $PURL

# Copy the intermediate CA's certificate chain to the share to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-chain.pem $INT_CA_CHAINFILE

# Start the intermediate CA
fabric-ca-server start
