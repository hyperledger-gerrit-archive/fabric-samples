#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

if [ $# -ne 2 ]; then
   echo "Usage: start-peer.sh <ORG> <PEER-NUM>"
   exit 1
fi

source $(dirname "$0")/env.sh
initPeerVars $1 $2

waitForFile $INT_CA_CHAINFILE

# Get the peer's TLS cert and copy to the appropriate place
export FABRIC_CA_CLIENT_TLS_CERTFILES=$INT_CA_CHAINFILE
fabric-ca-client enroll --enrollment.profile tls -u https://$PEER_NAME_PASS@$INT_CA_HOST:7054 \
                        -M /tmp/tls --csr.hosts $PEER_HOST
mkdir -p $TLSDIR
cp /tmp/tls/signcerts/* $CORE_PEER_TLS_CERT_FILE
cp /tmp/tls/keystore/* $CORE_PEER_TLS_KEY_FILE
rm -rf /tmp/tls

# Get peer's enrollment certificate
fabric-ca-client enroll -u https://$PEER_NAME_PASS@$INT_CA_HOST:7054 -M $CORE_PEER_LOCALMSPID

# Start the peer
cd $MYHOME
peer node start
