#!/bin/bash
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

function _exit(){
    printf "Exiting:%s\n" "$1"
    exit -1
}

# Where am I?
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

cd "${DIR}/organization/magnetocorp/configuration/cli"
docker-compose -f docker-compose.yml up -d cliMagnetoCorp

echo "
 Install and Instantiate a Smart Contract in either langauge

 JavaScript Contract:

 docker exec cliMagnetoCorp peer chaincode install -n papercontract -v 0 -p /opt/gopath/src/github.com/contract -l node
 docker exec cliMagnetoCorp peer chaincode instantiate -n papercontract -v 0 -l node -c '{\"Args\":[\"org.papernet.commercialpaper:instantiate\"]}' -C mychannel -P \"AND ('Org1MSP.member')\"

 Java Contract:

 docker exec cliMagnetoCorp peer chaincode install -n papercontract -v 0 -p /opt/gopath/src/github.com/contract-java -l java
 docker exec cliMagnetoCorp peer chaincode instantiate -n papercontract -v 0 -l java -c '{\"Args\":[\"org.papernet.commercialpaper:instantiate\"]}' -C mychannel -P \"AND ('Org1MSP.member')\"


 Run Applications in either langauage (can be different from the Smart Contract)

 JavaScript Client Aplications:

 To add identity to the wallet:   node addToWallet.js
 To issue the paper           :   node issue.js

 Java Client Applications:

 (remember to build the Java first with 'mvn')

 To add identity to the wallet:   java addToWallet
 To issue the paper           :   java issue
"

echo "Suggest that you change to this dir>  cd ${DIR}/organization/magnetocorp/"
