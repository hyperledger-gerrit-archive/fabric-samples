#!/bin/bash -e
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# exit on first error

Parse_Arguments() {
  while [ $# -gt 0 ]; do
    case $1 in
      --byfn_eyfn_Tests)
        byfn_eyfn_Tests
        ;;
      --fabcar_Tests)
        fabcar_Tests
        ;;
    esac
    shift
  done
}

# run byfn,eyfn tests
byfn_eyfn_Tests() {
  echo
  echo " ###### Execute Byfn and Eyfn Tests ######"
  ./byfn_eyfn.sh
}
# run fabcar tests
fabcar_Tests() {
  echo " #############################"
  echo "npm version ------> $(npm -v)"
  echo "node version ------> $(node -v)"
  echo " #############################"
  echo
  echo "###### Execute FabCar Tests ######"
  ./fabcar.sh
}

Parse_Arguments $@
