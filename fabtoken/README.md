
This is a sample Fabtoken application that demonstrates how to perform token operations
with the Fabric network using Node.js SDK.

Refer to the following documents for details of Fabtoken API in Node.js SDK.
* [Fabtoken tutorial](https://fabric-sdk-node.github.io/master/tutorial-fabtoken.html)
* [TokenClient JavaScript document](https://fabric-sdk-node.github.io/master/TokenClient.html)

Follow the instructions to setup and run the sample application fabtoken.js.
You may examine the fabtoken.js file for how to create users via pre-generated crypto materials
and how to invoke the token APIs.

### Setup
* Start fabric network: `./startFabric.sh`
 * It uses the "basic-network", where crypto materials are pre-generated
 * Use "user1" and "user2" for fabtoken operations

* Change to "javascript" directory: `cd javascript`

* Install all required packages: `npm install`

### Run the sample application

#### Issue
* node fabtoken issue <username> <token_type> <quantity>
* example: issue a token to user1 with type of "USD" and quantity of 100; then issue another token to user1 with type of "EURO" and quantity of 200.

```
   node fabtoken issue user1 USD 100
   node fabtoken issue user1 EURO 200
```

#### List
* node fabtoken list <username>
* the list operation returns a list of tokens and each token has a tx_id and index
* select a token to transfer or redeem and pass "tx_id" and "index" as input parameters
* example: list user1's tokens

```
   node fabtoken list user1

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
```

#### Transfer
* node fabtoken transfer <from_user> <to_user> <transfer_quantity> <remaining_quantity> <tx\_id> <index>
* <tx\_id> and <index> are the "tx\_id" and "index" returned from the list operation
* <transfer_quantity> is the quantity you want to transfer and <remaining_quantity> is the remaining quantity after transfer
* both numbers are required and they must be added up to the same quantity as the original token. Otherwise, the transaction will be invalidated.
* example: user1 transfer 30 quantity of the token to user2 and remaining quanity is 70 (100 - 30)

```
   node fabtoken transfer user1 user2 30 70 c9b1211d9ad809e6ee1b542de6886d8d1d9e1c938d88eff23a3ddb4e8c080e4d 0
```

#### Redeem
* node fabtoken redeem <username> <redeem\_quantity> <tx\_id> <index>
* <tx\_id> and <index> are the "tx\_id" and "index" returned from the list operation
* example: user2 redeems "10" quantity of the token as specified by <tx\_id> and <index>

```
   node fabtoken redeem user2 10 477c7bf2002814497c228fd8cbc4d80c8b7f1602b2c17ffadb6cf7e5783fa47a 0
```
