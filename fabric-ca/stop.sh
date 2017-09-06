#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

set -e
SDIR=$(dirname "$0")
source $SDIR/scripts/env.sh

docker-compose down
rm -rf $SDIR/share
