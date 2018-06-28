#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Purpose : Update the status of manuscripts in Publishing House Blockchain(PHBC) based on the status of manuscripts published in Conference Blockchain(CBC).
# This script contains REST API request to invoke PHBC to update manuscript status.

starttime=$(date +%s)

source restAPIs.sh

if [ $# -ne 2 ]; then
    echo -e "Expecting two arguments \n 1. CBC authorization token \n 2. PHBC authorization token"
    exit 1
fi

# Authorization tokens
CBC_TOKEN=$1
PHBC_TOKEN=$2

echo "Querying Manuscript IDs in the CBC"
CBC_manuscript_list=$(CBC_GET queryAllPaperIDs "" $CBC_TOKEN)

if [[ "$CBC_manuscript_list" != "" ]] ;then

    for id in $CBC_manuscript_list
    do
		# Check the status of manuscript in CBC
    	CBC_manuscript_status=$(CBC_GET queryPaperStatus "$id" $CBC_TOKEN)

        if [ "$CBC_manuscript_status" == "accepted" ] || [ "$CBC_manuscript_status" == "rejected" ] ; then

		    # if the status of manuscript in CBC is 'accepted', update the status of the same manuscript in PHBC as 'accepted'.
		    PHBC_manuscript_TRN_ID=$(PHBC_POST update_paper "[\"$id\",\"$CBC_manuscript_status\"]" $PHBC_TOKEN)
			echo "PHBC Manuscript $id Transaction ID is $PHBC_manuscript_TRN_ID"
			echo
        else
			echo "No need to update PHBC Manuscript $id"
	    fi
    done
else
    echo "CBC manuscript list is empty."
fi

echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
