#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

ACP_PATH=$GOPATH"/src/github.com/hyperledger/fabric-samples/adv-commercial-paper"
ORG_PATH=$ACP_PATH"/organization"
SHARED_PATH=$ACP_PATH"/shared"
GLOBAL_TARGET=$SHARED_PATH"/identity/organization"

function removeSharedIdentities () {

  org=$1

  echo Removing identities for $org

  path=$GLOBAL_TARGET"/"$org

  rm -r $path || true

}

function removeOrgIdentities () {

  org=$1

  echo Removing identities for $org

  path_ca=$ORG_PATH"/"$org"/identity/ca"
  path_orderer=$ORG_PATH"/"$org"/identity/orderer"
  path_organization=$ORG_PATH"/"$org"/identity/organization"
  path_peer=$ORG_PATH"/"$org"/identity/peer"
  path_user=$ORG_PATH"/"$org"/identity/user"
  path_cli_crypto=$ORG_PATH"/"$org"/configuration/cli/crypto-config"
  path_orderer_crypto=$ORG_PATH"/"$org"/configuration/orderer/crypto-config"

  rm -r $path_ca || true
  rm -r $path_orderer || true
  rm -r $path_organization || true
  rm -r $path_peer || true
  rm -r $path_user || true
  rm -r $path_cli_crypto || true
  rm -r $path_orderer_crypto || true

}

removeSharedIdentities "orderer.digibank.example.com"
removeSharedIdentities "digibank.example.com"
removeSharedIdentities "ecobank.example.com"
removeSharedIdentities "fedbank.example.com"
removeSharedIdentities "magnetocorp.example.com"

removeOrgIdentities "digibank"
removeOrgIdentities "ecobank"
removeOrgIdentities "fedbank"
removeOrgIdentities "magnetocorp"