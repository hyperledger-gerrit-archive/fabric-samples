#!/bin/bash
#
# Copyright 2018 CPqD. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a convenience script to stop and remove all containers.
# Usage: ./stopAll.sh

BASE_DIR=$PWD

#cd ${BASE_DIR}/web-application && \
# start application
#./stopApp.sh && \
cd ${BASE_DIR}/middleware && \
# start middleware
docker-compose down && \
cd ${BASE_DIR}/network && \
# start network
./cleanup.sh
