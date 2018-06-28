#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Purpose : Submit manuscript evaluation score by reviewers in Conference Blockchain(CBC)
# This script contains REST API request to submit reviewers scores for the assigned manuscript in CBC.

source restAPIs.sh

if [ $# -ne 1 ]; then
    echo -e "Script expects one argument: \n 1. CBC organization's authorization token"
    exit 1
fi

CBC_TOKEN=$1

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer41\",\"paper_attach_4\",\"4\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_4 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer51\",\"paper_attach_5\",\"2\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_5 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer61\",\"paper_attach_6\",\"5\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_6 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer101\",\"paper_attach_10\",\"1\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_10 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer111\",\"paper_attach_11\",\"5\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_11 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer121\",\"paper_attach_12\",\"2\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_12 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer42\",\"paper_attach_4\",\"3\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_4 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer52\",\"paper_attach_5\",\"2\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_5 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer62\",\"paper_attach_6\",\"4\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_6 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer102\",\"paper_attach_10\",\"2\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_10 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer112\",\"paper_attach_11\",\"4\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_11 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer122\",\"paper_attach_12\",\"3\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_12 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer43\",\"paper_attach_4\",\"4\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_4 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer53\",\"paper_attach_5\",\"2\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_5 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer63\",\"paper_attach_6\",\"4\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_6 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer103\",\"paper_attach_10\",\"3\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_10 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer113\",\"paper_attach_11\",\"5\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_11 : $TRX_ID"

TRX_ID=$(CBC_POST get_reviewers_decision "[\"reviewer123\",\"paper_attach_12\",\"2\"]" $CBC_TOKEN)
echo "Transaction ID paper_attach_12 : $TRX_ID"

echo "Completed manuscript review evaluations in the CBC"
