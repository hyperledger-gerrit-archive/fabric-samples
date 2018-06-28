#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Purpose : Double/concurrent submission validation of Conferece Blockchain(CBC) manuscripts by comparing with manuscripts in Publishing house blockchain(PHBC)
# This script contains REST API requests to query Publishing house blockchain (PHBC) and invoke CBC.

starttime=$(date +%s)

source restAPIs.sh

if [ $# -ne 3 ]; then
    echo -e "Expecting three arguments \n 1. CBC authorization token \n 2. PHBC authorization token \n 3. No. of manuscripts"
    exit 1
fi

# Authorization tokens
CBC_TOKEN=$1
PHBC_TOKEN=$2

echo "Checking manuscript availability in the PHBC"
for ((i = 1; i <= $3; i++)); do

	paperstatus=$(PHBC_GET queryPaperStatus "paper_attach_$i" $PHBC_TOKEN)

	# Status of the manuscript in CBC is updated based on the manuscript availability & its status in PHBC.
    if [ "$paperstatus" == "rejected" ]; then

	    # If status of the manuscript in PHBC is 'rejected', update the status of the same manuscript in
        # CBC and PHBC as 'submitted'.
       	echo "The given manuscript has status "rejected" in the PHBC"

        PHBC_submitted_TXN_ID=$(PHBC_POST update_paper "[\"paper_attach_$i\", \"submitted\"]" $PHBC_TOKEN)
		echo "PHBC Manuscript Transaction ID is $PHBC_submitted_TXN_ID"

        CBC_submitted_TXN_ID=$(CBC_POST update_paper "[\"paper_attach_$i\",\"submitted\"]" $CBC_TOKEN)
		echo "CBC Manuscript Transaction ID is $CBC_submitted_TXN_ID"
		echo

	elif [ "$paperstatus" == "accepted" ] || [ "$paperstatus" == "submitted" ] ; then

		if [ $paperstatus == "accepted" ]; then
	        # If status of the manuscript in PHBC is 'accepted', update the status of the same manuscript
            # in CBC as 'rejected - double submission'.
      		newstatus="manuscript rejected - double submission"
        else
	        # If status of the manuscript in PHBC is 'submitted', update the status of the same manuscript
            # in CBC as 'rejected - concurrent submission'.
			newstatus="manuscript rejected - concurrent submission"
		fi

		CBC_manuscript_TXN_ID=$(CBC_POST update_paper "[\"paper_attach_$i\",\"$newstatus\"]" $CBC_TOKEN)
        echo "CBC Manuscript Transaction ID is $CBC_manuscript_TXN_ID"
   	    echo

    else
	    # if status of the manuscript in PHBC is 'Not available', update the status of the same manuscript in CBC as 'submitted'
        # and add a new manuscript entry in PHBC with status as 'submitted'
       	echo "The given manuscript is not available in the PHBC"

        #Add manuscript to the PHBC
		PHBC_add_manuscript_TXN_ID=$(PHBC_POST add_paper "[\"paper_attach_$i\",\"submitted\",\"pc_01\"]" $PHBC_TOKEN)

		echo "PHBC Manuscript Transaction ID is $PHBC_add_manuscript_TXN_ID"

		#Update CBC manuscript status
		CBC_manuscript_status_update_TXN_ID=$(CBC_POST update_paper "[\"paper_attach_$i\",\"submitted\"]" $CBC_TOKEN)

   	    echo "CBC Manuscript Transaction ID is $CBC_manuscript_status_update_TXN_ID"
        echo
    fi
done

echo "Completed manuscripts validation in CBC"
echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
