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

cd "${DIR}/organization/digibank/configuration/cli"
docker-compose -f docker-compose.yml up -d cliDigiBank

echo "

 Install and Instantiate a Smart Contract as 'Magnetocorp'

 
 Run Applications in either langauage (can be different from the Smart Contract)

 JavaScript Client Aplications:

 To add identity to the wallet:   node addToWallet.js
    < issue the paper run as Magentocorp>
 To buy the paper             :   node buy.js
 To redeem the paper          :   node redeem.js

 Java Client Applications:

 (remember to build the Java first with 'mvn clean package')

    < issue the paper run as Magentocorp>
 To buy the paper             :   node buy.js
 To redeem the paper          :   node redeem.js

"
echo "Suggest that you change to this dir>  cd ${DIR}/organization/digibank"