#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Purpose: Register and enroll new users in all Organization's, Create and Join Publishing House Blockchain (PHBC) Channel, 
# Install and Instantiate publishing house chaincode.

starttime=$(date +%s)

# Calling restAPIs script (script is sourced) ...
source scripts/restAPIs.sh

# PHBC peers
PHBC_peer1="peer0.ieee.example.com"
PHBC_peer2="peer1.ieee.example.com"
PHBC_peer3="peer0.springer.example.com"
PHBC_peer4="peer1.springer.example.com"
PHBC_peer5="peer0.elsevier.example.com"
PHBC_peer6="peer1.elsevier.example.com"
PHBC_peer7="peer0.acm.example.com"
PHBC_peer8="peer1.acm.example.com"

# Enroll user on each Organization (IEEE, Springer, Elsevier, ACM)
# PHBC_ENROLL <username> <org_name>
echo "#### Enroll user on each Organization (IEEE, Springer, Elsevier, ACM) ####"
IEEE_TOKEN=$(PHBC_ENROLL user1 IEEE)
echo "IEEE token: $IEEE_TOKEN"
echo

Springer_TOKEN=$(PHBC_ENROLL user2 Springer)
echo "Springer token: $Springer_TOKEN"
echo

Elsevier_TOKEN=$(PHBC_ENROLL user3 Elsevier)
echo "Elsevier token: $Elsevier_TOKEN"
echo

ACM_TOKEN=$(PHBC_ENROLL user4 ACM)
echo "ACM token: $ACM_TOKEN"
echo


# Publishing House Blockchain (PHBC) channel creation
# PHBC_Channel_Create <token>
echo "#### Publishing House Blockchain channel creation ####"
PHBC_Channel_resp=$(PHBC_Channel_Create $IEEE_TOKEN)
echo "Channel creation response: $PHBC_Channel_resp"
echo
sleep 5


# Join peers to Publishing House Blockchain channel
# Assuming two peers per organization: PHBC_Channel_Join <token> <peer1> <peer2>
echo "#### Join channel on Organizations (IEEE, Springer, Elsevier, ACM) ####"
IEEE_join=$(PHBC_Channel_Join $IEEE_TOKEN $PHBC_peer1 $PHBC_peer2)
echo "IEEE response:$IEEE_join"

Springer_join=$(PHBC_Channel_Join $Springer_TOKEN $PHBC_peer3 $PHBC_peer4)
echo "Springer response: $Springer_join"

Elsevier_join=$(PHBC_Channel_Join $Elsevier_TOKEN $PHBC_peer5 $PHBC_peer6)
echo "Elsevier response: $Elsevier_join"

ACM_join=$(PHBC_Channel_Join $ACM_TOKEN $PHBC_peer7 $PHBC_peer8)
echo "ACM response: $ACM_join"
echo


# Install chaincode on Organizations (IEEE, Springer, Elsevier, ACM)
# PHBC_CC_Install <token> <peer1> <peer2>
echo "#### Install chaincode on Organizations (IEEE, Springer, Elsevier, ACM) ####"
IEEE_CC_Install=$(PHBC_CC_Install $IEEE_TOKEN $PHBC_peer1 $PHBC_peer2)
echo "IEEE response: $IEEE_CC_Install"

Springer_CC_Install=$(PHBC_CC_Install $Springer_TOKEN $PHBC_peer3 $PHBC_peer4)
echo "Springer response: $Springer_CC_Install"

Elsevier_CC_Install=$(PHBC_CC_Install $Elsevier_TOKEN $PHBC_peer5 $PHBC_peer6)
echo "Elsevier response: $Elsevier_CC_Install"

ACM_CC_Install=$(PHBC_CC_Install $ACM_TOKEN $PHBC_peer7 $PHBC_peer8)
echo "ACM response: $ACM_CC_Install"
echo

# Instantiate chaincode on peers of Organizations (IEEE, Springer, Elsevier, ACM)
# PHBC_CC_Instantiate <token>
echo "#### Instantiate chaincode on peers of Organizations (IEEE, Springer, Elsevier, ACM) ####"
instantiate_resp=$(PHBC_CC_Instantiate $IEEE_TOKEN)
echo "Chaincode instantiation response: $instantiate_resp"
echo

echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
