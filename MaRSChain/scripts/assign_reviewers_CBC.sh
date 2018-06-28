#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
#  http://www.apache.org/licenses/LICENSE-2.0
#

# Purpose : Assign reviewers to the manuscripts in Conference Blockchain (CBC).
# This script contains REST API request to assign reviewers for manuscript evaluation in CBC.

source restAPIs.sh

if [ $# -ne 2 ]; then
    echo -e "Expecting two arguments: \n 1. CBC organization's authorization token \n 2. No. of manuscripts"
    exit 1
fi

CBC_TOKEN=$1

for ((i = 1; i <= $2; i++)); do
	# Assign reviewers to the manuscripts
	CBC_assign_reviewers_TRX_ID=$(CBC_POST assign_reviewers "[\"paper_attach_$i\",\"reviewer${i}1\",\"reviewer${i}2\",\"reviewer${i}3\"]" $CBC_TOKEN)
	echo "CBC Manuscript Transaction ID is $CBC_assign_reviewers_TRX_ID"
	echo
done
echo "Completed assigning reviewers for given manuscipts"
