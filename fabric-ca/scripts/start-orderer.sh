#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

if [ $# -ne 2 ]; then
   echo "Usage: start-orderer.sh <ORG> <ORDERER-NUM>"
   exit 1
fi

source $(dirname "$0")/env.sh
initOrdererVars $1 $2

# Wait for setup to complete sucessfully
waitForFile $SETUP_SUCCESS_FILE

# Get orderer's TLS cert and copy to the appropriate place
export FABRIC_CA_CLIENT_TLS_CERTFILES=$INT_CA_CHAINFILE
fabric-ca-client enroll -d --enrollment.profile tls -u https://$ORDERER_NAME_PASS@$INT_CA_HOST:7054 \
                        -M /tmp/tls --csr.hosts $ORDERER_HOST
mkdir -p $TLSDIR
cp /tmp/tls/keystore/* $ORDERER_GENERAL_TLS_PRIVATEKEY
cp /tmp/tls/signcerts/* $ORDERER_GENERAL_TLS_CERTIFICATE
rm -rf /tmp/tls

# Get orderer's ECert
fabric-ca-client enroll -d -u https://$ORDERER_NAME_PASS@$INT_CA_HOST:7054 -M $ORDERER_GENERAL_LOCALMSPDIR
# Copy the admin cert to the orderer's local MSP
copyAdminCert $ORDERER_GENERAL_LOCALMSPDIR

# Wait for the genesis block to be created
waitForFile $ORDERER_GENERAL_GENESISFILE

# Start the orderer
export ORDERER_GENERAL_LOGLEVEL=debug
export ORDERER_DEBUG_BROADCASTTRACEDIR=/$DATA/logs
env | grep ORDERER
orderer
