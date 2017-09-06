#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

SDIR=$(dirname "$0")
source $SDIR/scripts/env.sh

NETWORK=fabric-ca
ROOT_CA_DCFILE=$SDIR/docker-compose-fabric-ca-root.yml
INT_CA_DCFILE=$SDIR/docker-compose-fabric-ca-intermediate.yml
SETUP_DCFILE=$SDIR/docker-compose-fabric-setup.yml
START_DCFILE=$SDIR/docker-compose-fabric-start.yml
RUN_DCFILE=$SDIR/docker-compose-fabric-run.yml
