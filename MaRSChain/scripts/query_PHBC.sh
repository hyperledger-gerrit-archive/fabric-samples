#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#

# Purpose : Query Manuscripts' status in the Publishing House Blockchain (PHBC)
# This script contains REST API request to query manuscript status in PHBC.

source restAPIs.sh

if [ $# -ne 1 ]; then
    echo -e "Expecting one argument \n 1. PHBC Authorization token"
    exit 1
fi

PHBC_TOKEN=$1

# Query PHBC chaincode to get manuscripts' status"
query_paper_info=$(PHBC_GET queryAllPapers "" $PHBC_TOKEN)
echo $query_paper_info
echo "Completed querying manuscripts status in the PHBC"
