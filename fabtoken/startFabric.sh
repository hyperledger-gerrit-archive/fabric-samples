#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error
set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)

# launch network; create channel and join peer to channel
cd ../basic-network
./start.sh

cat <<EOF

Total setup execution time : $(($(date +%s) - starttime)) secs ...

Next, use the FabToken application to interact with the Fabric network.

  Start by changing into the "javascript" directory:
    cd javascript

  Next, install all required packages:
    npm install

  Then run the fabtoken application to perform the token operations.

    node fabtoken issue <username> <token_type> <quantity>
      - example 1: node fabtoken issue user1 USD 100
      - example 2: node fabtoken issue user1 EURO 200
      - issue a token to user1 in "USD" type and 100 quantity and issue another token to user1 in "EURO" type and 200 quantity.
    node fabtoken list <username>
      - example: node fabtoken list user1
      - user1 lists his tokens
      - a user can only list, transfer, and redeem tokens owned by himself.
      - the list operation returns a list of tokens and each token has a tx_id and index.
        [ { id:
               { tx_id: 'ab5670d3b20b6247b17a342dd2c5c4416f79db95c168beccb7d32b3dd382e5a5',
                 index: 0 },
            type: 'EURO',
            quantity: '200' },
          { id:
               { tx_id: 'c9b1211d9ad809e6ee1b542de6886d8d1d9e1c938d88eff23a3ddb4e8c080e4d',
                 index: 0 },
            type: 'USD',
            quantity: '100' }]
      - select a token to transfer or redeem and pass "tx_id" and "index" as input parameters
    node fabtoken transfer <from_user> <to_user> <transfer_quantity> <remaining_quantity> <tx_id> <index>
      - example: node fabtoken transfer user1 user2 30 70 c9b1211d9ad809e6ee1b542de6886d8d1d9e1c938d88eff23a3ddb4e8c080e4d 0
      - user1 transfers to user2 "30" quantity of the token as specified by <tx_id> and <index>
      - <tx_id> and <index> are the "tx_id" and "index" returned from the list operation
      - "30" is the quantity you want to transfer and "70" is the remaining quantity after transfer.
        Both numbers are required and they must be added up to the same quantity as the original token.
        Otherwise, the transaction will be invalidated.
    node fabtoken redeem <username> <redeem_quantity> <tx_id> <index>
      - example: node fabtoken redeem user2 10 477c7bf2002814497c228fd8cbc4d80c8b7f1602b2c17ffadb6cf7e5783fa47a 0
      - user2 redeems "10" quantity of the token as specified by <tx_id> and <index>
      - <tx_id> and <index> are the "tx_id" and "index" returned from the list operation

EOF
