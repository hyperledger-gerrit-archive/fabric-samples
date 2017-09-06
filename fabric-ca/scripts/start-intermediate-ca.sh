#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Initialize the intermediate CA
fabric-ca-server init -b $BOOTSTRAP_USER_PASS -u $PARENT_URL

# Copy the intermediate CA's certificate chain to the data directory to be used by others
cp $FABRIC_CA_SERVER_HOME/ca-chain.pem $TARGET_CHAINFILE

# Start the intermediate CA
fabric-ca-server start
