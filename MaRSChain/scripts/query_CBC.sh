#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Purpose : Query Manuscripts' Status in the Conference Blockchain(CBC)
# This script contains REST API request to query manuscript information from CBC

source restAPIs.sh

if [ $# -ne 2 ]; then
    echo -e "Expecting two arguments \n 1. CBC organization authorization token \n 2. No. of manuscripts"
    exit 1
fi

CBC_TOKEN=$1

for ((i = 1; i <= $2; i++)); do
    # Query CBC chaincode to get manuscripts status"
	query_manuscript_status=$(CBC_GET querySubmittedPaperInfo "paper_attach_$i" $CBC_TOKEN)
    echo $query_manuscript_status
done

echo "Completed querying manuscripts' information in the CBC"
