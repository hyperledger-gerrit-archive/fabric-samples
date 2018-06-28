#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#

# Purpose : Consolidate manuscript final score in Conference blockchain (CBC).
# This script contains REST API request to consolidate all the scores given by assigned reviewers.

source restAPIs.sh

if [ $# -ne 1 ]; then
    echo -e "Script expects one argument: \n 1. CBC organization's authorization token"
    exit 1
fi

CBC_TOKEN=$1

CBC_paper_score_TRX_ID=$(CBC_POST make_decision "[]" $CBC_TOKEN)

echo "CBC Manuscript Consolidation Transaction ID is  $CBC_paper_score_TRX_ID"
