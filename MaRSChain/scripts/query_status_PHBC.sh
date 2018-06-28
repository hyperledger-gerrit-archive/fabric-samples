#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Purpose : Query manuscripts in Publishing House Blockchain (PHBC)
# This script contains REST API request to query all manuscripts status in PHBC

source restAPIs.sh

if [ $# -ne 2 ]; then
    echo -e "Expecting two arguments \n 1. PHBC authorization token \n 2. No. of manuscripts"
    exit 1
fi

PHBC_TOKEN=$1

for ((i = 1; i <= $2; i++)); do
    # Query PHBC chaincode to get all manuscipts status
    status=$(PHBC_GET queryPaperStatus "paper_attach_$i" $PHBC_TOKEN)
    echo "PHBC Manuscript $i status : $status"
	echo
done
