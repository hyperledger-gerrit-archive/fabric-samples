#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

if [ $# -ne 1 ]; then
   echo "Usage: start-root-ca.sh <ORG>"
   exit 1
fi

source $(dirname "$0")/env.sh
initOrgVars $1

# Initialize the root CA
export FABRIC_CA_SERVER_HOME=/etc/hyperledger/fabric-ca
export FABRIC_CA_SERVER_CA_NAME=$ROOT_CA_NAME
export FABRIC_CA_SERVER_TLS_ENABLED=true
export FABRIC_CA_SERVER_CSR_HOSTS=$ROOT_CA_HOST
export FABRIC_CA_SERVER_DEBUG=true
fabric-ca-server init -b $ROOT_CA_ADMIN_USER_PASS

# Copy the root CA's signing certificate to the share to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-cert.pem $ROOT_CA_CERTFILE

# Start the root CA
fabric-ca-server start
