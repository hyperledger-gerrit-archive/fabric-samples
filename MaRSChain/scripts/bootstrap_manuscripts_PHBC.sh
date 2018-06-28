#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Purpose : Bootstrap Manuscripts in to Publishing House Blockchain(PHBC)
# This script contains REST API requests to bootstap manuscripts with different statutes in to PHBC.

source restAPIs.sh

if [ $# -ne 3 ]; then
    echo -e "Expecting three argument : \n 1. IEEE Authorization token \n 2. Springer Token \n 3. ACM Token"
    exit 1
fi

IEEE_TOKEN=$1
Springer_TOKEN=$2
ACM_TOKEN=$3

# Bootstraping manuscripts having status as 'submitted'
echo "#### Bootstraping manuscripts to PHBC with status as 'submitted' ####"
for ((i = 1; i <= 3; i++)); do
	submitted_TXN_ID=$(PHBC_POST add_paper "[\"paper_attach_$i\", \"submitted\", \"pc_01\"]" $IEEE_TOKEN)
	echo "PHBC Manuscript Transaction ID is $submitted_TXN_ID"
	echo
done

# Bootstraping manuscripts having status as 'rejected'
echo "#### Bootstraping manuscripts to the PHBC with status as 'rejected' ####"
for ((i = 4; i <= 6; i++)); do
	rejected_TXN_ID=$(PHBC_POST add_paper "[\"paper_attach_$i\", \"rejected\", \"pc_01\"]" $Springer_TOKEN)
    echo "PHBC Manuscript Transaction ID is $rejected_TXN_ID"
    echo
done

# Bootstraping manuscripts having status as 'accepted'
echo "#### Bootstraping manuscripts to the PHBC with status as 'accepted' ####"
for ((i = 7; i <= 9; i++)); do
	accepted_TXN_ID=$(PHBC_POST add_paper "[\"paper_attach_$i\", \"accepted\", \"pc_01\"]" $ACM_TOKEN)
    echo "PHBC Manuscript Transaction ID is $accepted_TXN_ID"
    echo
done
