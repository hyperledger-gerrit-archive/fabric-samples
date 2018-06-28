#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Purpose: Submit Manuscripts to the Conference Blockchain (CBC)
# This script contains REST API request to submit the given number of manuscripts in to CBC.

source restAPIs.sh

if [ $# -ne 2 ]; then
    echo -e "Expecting two arguments \n 1. Authorization token \n 2. No. of manuscripts"
    exit 1
fi

CBC_TOKEN=$1

for ((i = 1; i <= $2; i++)); do

    TRX_ID=$(CBC_POST submit_paper "[\"a1$i\",\"a2$i\", \"a3$i\", \"attach_$i\"]" $CBC_TOKEN)

    echo "CBC Manuscript $i transaction ID is $TRX_ID"
	echo
done

echo "Completed manuscripts submission in to the CBC"
