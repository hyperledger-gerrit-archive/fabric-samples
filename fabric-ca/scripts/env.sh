#!/bin/bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

#
# This file sets environment variables on a global, per-org (see initOrgVars),
# per-orderer (see initOrdererVars), or per-peer (see initPeerVars) basis.
#

# Name of the docker-compose network
NETWORK=fabric-ca

# Names of the orderer organizations and number of orderer nodes
ORDERER_ORGS="org0"
NUM_ORDERERS=1

# Names of the peer organizations and number of peer nodes
PEER_ORGS="org1 org2"
NUM_PEERS=2

# All org names
ORGS="$ORDERER_ORGS $PEER_ORGS"

# The volume mount to share data between containers
DATA=data
# The path to the genesis block
GENESIS_BLOCK_FILE=/$DATA/genesis.block
# The path to a channel transaction
CHANNEL_TX_FILE=/$DATA/channel.tx
# Name of test channel
CHANNEL_NAME=mychannel

# Log directory 
LOGDIR=/$DATA/logs

# Name of a the file to create when setup is successful
SETUP_SUCCESS_FILE=/$DATA/setup.successful

# Affiliation is not used to limit users in this sample, so just put
# all identities in the same affiliation.
export FABRIC_CA_CLIENT_ID_AFFILIATION=org1

# Set to true to populate the "admincerts" folder of MSPs
ADMINCERTS=true

# initOrgVars <ORG>
function initOrgVars {
   if [ $# -ne 1 ]; then
      echo "Usage: initOrgVars <ORG>"
      exit 1
   fi
   ORG=$1
   ORG_CONTAINER_NAME=${ORG//./-}
   ROOT_CA_HOST=rca-${ORG}
   INT_CA_HOST=ica-${ORG}
   ROOT_CA_NAME=rca-${ORG}
   INT_CA_NAME=ica-${ORG}
   ROOT_CA_ADMIN_USER=rca-${ORG}-admin
   INT_CA_ADMIN_USER=ica-${ORG}-admin
   ROOT_CA_ADMIN_PASS=${ROOT_CA_ADMIN_USER}pw
   INT_CA_ADMIN_PASS=${INT_CA_ADMIN_USER}pw
   ROOT_CA_ADMIN_USER_PASS=${ROOT_CA_ADMIN_USER}:${ROOT_CA_ADMIN_PASS}
   INT_CA_ADMIN_USER_PASS=${INT_CA_ADMIN_USER}:${INT_CA_ADMIN_PASS}
   ORDERER_NAME=orderer-${ORG}
   ORDERER_PASS=${ORDERER_NAME}pw
   ADMIN_NAME=admin-${ORG}
   ADMIN_PASS=${ADMIN_NAME}pw
   USER_NAME=user-${ORG}
   USER_PASS=${USER_NAME}pw
   ROOT_CA_CERTFILE=/${DATA}/${ORG}-ca-cert.pem
   INT_CA_CHAINFILE=/${DATA}/${ORG}-ca-chain.pem
   ANCHOR_TX_FILE=/${DATA}/orgs/${ORG}/anchors.tx
   ORG_MSP_ID=${ORG}MSP
   ORG_MSP_DIR=/${DATA}/orgs/${ORG}/msp
   ORG_ADMIN_CERT=${ORG_MSP_DIR}/admincerts/cert.pem
   # This needs to be on the shared volume as long as ADMINCERTS is true.
   ORG_ADMIN_HOME=/${DATA}/orgs/$ORG/admin
}

# initOrdererVars <NUM>
function initOrdererVars {
   if [ $# -ne 2 ]; then
      echo "Usage: initOrdererVars <ORG> <NUM>"
      exit 1
   fi
   initOrgVars $1
   NUM=$2
   ORDERER_HOST=orderer${NUM}-${ORG}
   ORDERER_NAME=orderer${NUM}-${ORG}
   ORDERER_PASS=${ORDERER_NAME}pw
   ORDERER_NAME_PASS=${ORDERER_NAME}:${ORDERER_PASS}
   MYHOME=/etc/hyperledger/orderer

   export FABRIC_CA_CLIENT=$MYHOME
   export ORDERER_GENERAL_LOGLEVEL=debug
   export ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
   export ORDERER_GENERAL_GENESISMETHOD=file
   export ORDERER_GENERAL_GENESISFILE=$GENESIS_BLOCK_FILE
   export ORDERER_GENERAL_LOCALMSPID=$ORG_MSP_ID
   export ORDERER_GENERAL_LOCALMSPDIR=$MYHOME/msp
   # enabled TLS
   export ORDERER_GENERAL_TLS_ENABLED=true
   TLSDIR=$MYHOME/tls
   export ORDERER_GENERAL_TLS_PRIVATEKEY=$TLSDIR/server.key
   export ORDERER_GENERAL_TLS_CERTIFICATE=$TLSDIR/server.crt
   export ORDERER_GENERAL_TLS_ROOTCAS=[$INT_CA_CHAINFILE]
}

# initPeerVars <ORG> <NUM>
function initPeerVars {
   if [ $# -ne 2 ]; then
      echo "Usage: initPeerVars <ORG> <NUM>: $*"
      exit 1
   fi
   initOrgVars $1
   NUM=$2
   PEER_HOST=peer${NUM}-${ORG}
   PEER_NAME=peer${NUM}-${ORG}
   PEER_PASS=${PEER_NAME}pw
   PEER_NAME_PASS=${PEER_NAME}:${PEER_PASS}
   MYHOME=/opt/gopath/src/github.com/hyperledger/fabric/peer
   TLSDIR=$MYHOME/tls

   export FABRIC_CA_CLIENT=$MYHOME
   export CORE_PEER_ID=$PEER_HOST
   export CORE_PEER_ADDRESS=$PEER_HOST:7051
   export CORE_PEER_LOCALMSPID=$ORG_MSP_ID
   export CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
   # the following setting starts chaincode containers on the same
   # bridge network as the peers
   # https://docs.docker.com/compose/networking/
   #export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=${COMPOSE_PROJECT_NAME}_${NETWORK}
   export CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=net_${NETWORK}
   # export CORE_LOGGING_LEVEL=ERROR
   export CORE_LOGGING_LEVEL=DEBUG
   export CORE_PEER_TLS_ENABLED=true
   export CORE_PEER_PROFILE_ENABLED=true
   export CORE_PEER_TLS_CERT_FILE=$TLSDIR/server.crt
   export CORE_PEER_TLS_KEY_FILE=$TLSDIR/server.key
   export CORE_PEER_TLS_ROOTCERT_FILE=$INT_CA_CHAINFILE
   # gossip variables
   export CORE_PEER_GOSSIP_USELEADERELECTION=true
   export CORE_PEER_GOSSIP_ORGLEADER=false
   export CORE_PEER_GOSSIP_EXTERNALENDPOINT=$PEER_HOST:7051
   if [ $NUM -gt 1 ]; then
      # Point the non-anchor peers to the anchor peer, which is always the 1st peer
      export CORE_PEER_GOSSIP_BOOTSTRAP=peer1-${ORG}:7051
   fi
}

# Enroll the current org's admin identity if not already enrolled
function enrollFabricAdmin {
   if [ ! -d $ORG_ADMIN_HOME ]; then
      waitForFile "Waiting for $INT_CA_NAME to start" "$INT_CA_NAME has started" $INT_CA_CHAINFILE
      log "Enrolling admin '$ADMIN_NAME' with $INT_CA_HOST ..."
      export FABRIC_CA_CLIENT_HOME=$ORG_ADMIN_HOME
      export FABRIC_CA_CLIENT_TLS_CERTFILES=$INT_CA_CHAINFILE
      fabric-ca-client enroll -d -u https://$ADMIN_NAME:$ADMIN_PASS@$INT_CA_HOST:7054
      # If admincerts are required in the MSP, copy the cert there now and to my local MSP also
      if [ $ADMINCERTS ]; then
         mkdir -p $(dirname "${ORG_ADMIN_CERT}")
         cp $ORG_ADMIN_HOME/msp/signcerts/* $ORG_ADMIN_CERT
         mkdir $ORG_ADMIN_HOME/msp/admincerts
         cp $ORG_ADMIN_HOME/msp/signcerts/* $ORG_ADMIN_HOME/msp/admincerts
      fi
   fi
   export CORE_PEER_MSPCONFIGPATH=$ORG_ADMIN_HOME/msp
}

# Enroll the current org's user identity if not already enrolled
function enrollFabricUser {
   CORE_PEER_MSPCONFIGPATH=$ORG/user
   if [ ! -f $CORE_PEER_MSPCONFIGPATH ]; then
      waitForFile "Waiting for $INT_CA_NAME to start" "$INT_CA_NAME has started" $INT_CA_CHAINFILE
      log "Enrolling user for organization $ORG ..."
      export FABRIC_CA_CLIENT_HOME=orgs/$ORG/user
      export FABRIC_CA_CLIENT_TLS_CERTFILES=$INT_CA_CHAINFILE
      fabric-ca-client enroll -d -u https://$USER_NAME:$USER_PASS@$INT_CA_HOST:7054 -M $CORE_PEER_MSPCONFIGPATH
   fi
}

# Copy the org's admin cert into some target MSP directory
# This is only required if ADMINCERTS is enabled.
function copyAdminCert {
   if [ $# -ne 1 ]; then
      fatal "Usage: copyAdminCert <targetMSPDIR>"
   fi
   if $ADMINCERTS; then
      dstDir=$1/admincerts
      mkdir -p $dstDir
      waitForFile "Waiting for $ORG administator to enroll" "$ORG administrator is enrolled" $ORG_ADMIN_CERT
      cp $ORG_ADMIN_CERT $dstDir
   fi
}

# Create the TLS directories of the MSP folder if they don't exist.
# The fabric-ca-client should do this.
function finishMSPSetup {
   if [ $# -ne 1 ]; then
      fatal "Usage: finishMSPSetup <targetMSPDIR>"
   fi
   if [ ! -d $1/tlscacerts ]; then
      mkdir $1/tlscacerts
      cp $1/cacerts/* $1/tlscacerts
      if [ -d $1/intermediatecerts ]; then
         mkdir $1/tlsintermediatecerts
         cp $1/intermediatecerts/* $1/tlsintermediatecerts
      fi
   fi
}

# Wait for one or more files to exist
# waitForFile <waitMessage> <doneMessage> <file> [<file> ...]
function waitForFile {
   if [ $# -lt 3 ]; then
      fatal "Usage: too few args to waitForFile: $*"
   fi
   waitMsg=$1
   doneMsg=$2
   shift 2
   local count=1
   for file in $*; do
      until [ -f $file ]; do
         log "$count) $waitMsg ($file does not yet exist) ..."
         sleep 1
         count=$((count+1))
      done
   done
   log "$doneMsg"
}

# log a message
function log {
   echo "##### `date '+%Y-%m-%d %H:%M:%S'` $* #####"
}

# fatal a message
function fatal {
   log "FATAL: $* "
   exit 1
}
