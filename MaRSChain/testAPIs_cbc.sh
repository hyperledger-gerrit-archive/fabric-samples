#!/bin/bash
#
# Copyright TCS Ltd 2018 All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Purpose: Register and enroll new users in all Organization's, Create and Join Conference Blockchain (CBC) Channel, 
# Install and Instantiate Conference chaincode.

starttime=$(date +%s)

# Calling restAPIs script (script is sourced) ...
source scripts/restAPIs.sh

# CBC peers
CBC_peer1="peer0.pc1.example.com"
CBC_peer2="peer1.pc1.example.com"
CBC_peer3="peer0.pc2.example.com"
CBC_peer4="peer1.pc2.example.com"
CBC_peer5="peer0.pc3.example.com"
CBC_peer6="peer1.pc3.example.com"
CBC_peer7="peer0.pc4.example.com"
CBC_peer8="peer1.pc4.example.com"

# Enroll user on each Organization (PC1, PC2, PC3, PC4)
# CBC_ENROLL <username> <org_name>
echo "#### Enroll user on each Organization (PC1, PC2, PC3, PC4) ####"
PC1_TOKEN=$(CBC_ENROLL Jim PC1)
echo "PC1 token: $PC1_TOKEN"
echo

PC2_TOKEN=$(CBC_ENROLL Barry PC2)
echo "PC2 token: $PC2_TOKEN"
echo

PC3_TOKEN=$(CBC_ENROLL Digeo PC3)
echo "PC3 token: $PC3_TOKEN"
echo

PC4_TOKEN=$(CBC_ENROLL tom PC4)
echo "PC4 token: $PC4_TOKEN"
echo


# Conference Blockchain (CBC) channel creation
# CBC_Channel_Create <token>
echo "#### Conference Blockchain channel creation ####"
channel_resp=$(CBC_Channel_Create $PC1_TOKEN)
echo "Channel creation response: $channel_resp"
echo
sleep 5


# Join peer's to Conference Blockchain channel
# Assuming two peers per organization: CBC_Channel_Join <token> <peer1> <peer2>
echo "#### Join channel on Organizations (PC1, PC2, PC3, PC4) ####"
PC1_join=$(CBC_Channel_Join $PC1_TOKEN $CBC_peer1 $CBC_peer2)
echo "PC1 response: $PC1_join"

PC2_join=$(CBC_Channel_Join $PC2_TOKEN $CBC_peer3 $CBC_peer4)
echo "PC2 response: $PC2_join"

PC3_join=$(CBC_Channel_Join $PC3_TOKEN $CBC_peer5 $CBC_peer6)
echo "PC3 response: $PC3_join"

PC4_join=$(CBC_Channel_Join $PC4_TOKEN $CBC_peer7 $CBC_peer8)
echo "PC4 response: $PC4_join"
echo


# Install chaincode on Organizations (PC1, PC2, PC3, PC4)
# CBC_CC_Install <token> <peer1> <peer2>
echo "#### Install chaincode on Organizations (PC1, PC2, PC3, PC4) ####"
PC1_install=$(CBC_CC_Install $PC1_TOKEN $CBC_peer1 $CBC_peer2)
echo "PC1 response: $PC1_install"

PC2_install=$(CBC_CC_Install $PC2_TOKEN $CBC_peer3 $CBC_peer4)
echo "PC2 response: $PC2_install"

PC3_install=$(CBC_CC_Install $PC3_TOKEN $CBC_peer5 $CBC_peer6)
echo "PC3 response: $PC3_install"

PC4_install=$(CBC_CC_Install $PC4_TOKEN $CBC_peer7 $CBC_peer8)
echo "PC4 response: $PC4_install"
echo


# Instantiate chaincode on peers of Organizations (PC1, PC2, PC3, PC4)
# CBC_CC_Instantiate <token>
echo "##### Instantiate chaincode on peers of Organizations (PC1, PC2, PC3, PC4) ####"
instantiate_resp=$(CBC_CC_Instantiate $PC1_TOKEN)
echo "Instantiation response: $instantiate_resp"
echo

echo "Total execution time : $(($(date +%s)-starttime)) secs ..."
