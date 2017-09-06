#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#
# This script does everything required to run the fabric CA sample.
#

set -e

SDIR=$(dirname "$0")
source=$SDIR/env.sh

# Start with a clean share
rm -rf $SDIR/share
mkdir -p $SDIR/share/logs

# Create the docker-compose file
makeDocker.sh

# Start the docker container
docker-compose up -d
