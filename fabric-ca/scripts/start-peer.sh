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
fabric-ca-client enroll -d --enrollment.profile tls -u https://$PEER_NAME_PASS@$INT_CA_HOST:7054 \
                        -M /tmp/tls --csr.hosts $PEER_HOST
mkdir -p $TLSDIR
cp /tmp/tls/signcerts/* $CORE_PEER_TLS_CERT_FILE
cp /tmp/tls/keystore/* $CORE_PEER_TLS_KEY_FILE
rm -rf /tmp/tls

# Get peer's enrollment certificate
MSPDIR=$MYHOME/msp
fabric-ca-client enroll -d -u https://$PEER_NAME_PASS@$INT_CA_HOST:7054 -M $MSPDIR
# Copy the admin cert to the peer's local MSP
copyAdminCert $MSPDIR

# Start the peer
log "Starting peer '$PEER_NAME' with MSP at '$MSPDIR'"
export CORE_PEER_MSPCONFIGPATH=$MSPDIR
cd $MYHOME
peer node start
