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
source $SDIR/scripts/env.sh

LOGDIR=$SDIR/data/logs
LOGFILE=$LOGDIR/run.log

# Start with a clean data directory
rm -rf $SDIR/data
mkdir -p $LOGDIR

# Create the docker-compose file
makeDocker.sh

# Start the docker container
log "Creating docker containers ..."
docker-compose up -d
log "Docker containers have been created"

waitForFile "Waiting for the 'run' container to start the test" "The 'run' container is starting ..." $LOGFILE
tail -f $LOGFILE
