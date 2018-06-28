#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Purpose : Query Manuscripts' Status in Publishing House Blockchain(PHBC)
# This script contains REST API request to query PHBC blockchain to get manuscripts information

source restAPIs.sh

if [ $# -ne 2 ]; then
    echo -e "Expecting two arguments \n 1. PHBC authorization token \n 2. No. of Manuscripts"
    exit 1
fi

PHBC_TOKEN=$1

for ((i = 1; i <= $2; i++)); do
    # query PHBC chaincode to get manuscript information
    query_manuscript_info=$(PHBC_GET queryPaperInfo "paper_attach_$i" $PHBC_TOKEN)
    echo $query_manuscript_info
done




