#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

CHANNEL_NAME="$1"
CREATE_CHANNEL_FILE="$2"
: ${CHANNEL_NAME:="mychannel2"}
: ${CREATE_CHANNEL_FILE:="./channel-artifacts/channel2.tx"}

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

# signConfigtxAsOrdererOrg <configtx.pb>
# Set the ordererOrg admin of an org and signing the config update
signConfigtxAsOrdererOrg() {
  TX="$1"
  setOrdererGlobals
  set -x
  peer channel signconfigtx -f "${TX}"
  set +x
}

echo "Signing the create channel tx..."
signConfigtxAsOrdererOrg "$CREATE_CHANNEL_FILE"
signConfigtxAsPeerOrg 2 "$CREATE_CHANNEL_FILE"

exit 0
