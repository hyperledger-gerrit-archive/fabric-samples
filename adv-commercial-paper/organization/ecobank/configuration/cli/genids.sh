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
GLOBAL_TARGET=$SHARED_PATH"/identity"

function generateIdentities () {

  org=$1

  component="cli"
  echo Generating $component identities for $org

  orgSource=$ORG_PATH"/"$org"/configuration/"$component"/crypto-config"

  rm -r $orgSource"/peerOrganizations" || true

  cryptogen generate --config=./crypto-config.yaml --output ./crypto-config

}

function copyIdentities () {
  org=$1
  fqorg=$2
  componentPrefix=$3

  caOrg="ca."$fqorg
  orgAdmin="Admin@"$fqorg
  orgUser1="User1@"$fqorg
  component="peer"
  orgComponent1=$component$componentPrefix"."$fqorg

  orgSource=$ORG_PATH"/"$org"/configuration/cli/crypto-config"
  orgTarget=$ORG_PATH"/"$org"/identity"
  componentPath=$component"Organizations"

  echo Copying Organization information
  SOURCE=$orgSource/$componentPath/$fqorg/msp
  TARGET=$orgTarget/organization/$fqorg
  mkdir -p $TARGET && cp -R $SOURCE $TARGET/msp
  GLOBAL_TARGET=$GLOBAL_TARGET/organization/$fqorg
  mkdir -p $GLOBAL_TARGET && cp -R $SOURCE $GLOBAL_TARGET/msp
  SOURCE=$orgSource/$componentPath/$fqorg/tlsca
  TARGET=$orgTarget/organization/$fqorg
  cp -R $SOURCE $TARGET

  echo Copying CA information
  SOURCE=$orgSource/$componentPath/$fqorg/ca/
  TARGET=$orgTarget/ca/$caOrg
  mkdir -p $TARGET && cp -R $SOURCE $TARGET

  echo Copying User information
  SOURCE=$orgSource/$componentPath/$fqorg/users/$orgAdmin/
  TARGET=$orgTarget/user/$orgAdmin/
  mkdir -p $TARGET && cp -R $SOURCE $TARGET
  SOURCE=$orgSource/peerOrganizations/$fqorg/users/$orgUser1/
  TARGET=$orgTarget/user/$orgUser1/
  mkdir -p $TARGET && cp -R $SOURCE $TARGET

  echo Copying $component information
  SOURCE=$orgSource/$componentPath/$fqorg/$component"s"/$orgComponent1
  TARGET=$orgTarget/$component
  mkdir -p $TARGET && cp -R $SOURCE $TARGET

}

org="ecobank"
orgDNS=$org".example.com"

generateIdentities $org

copyIdentities $org $orgDNS 3