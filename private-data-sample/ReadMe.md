# Secret Reserve Auction

This is a "Secret Reserve Auction" PoC showcasing use of Private-Data feature introduced in Hyperledger Fabric(HLF) v1.2 where sellers and buyers are part of channel eliminating the auctioneer.

- Sellers can list assets on ledger along with auction period
- This application leverages the private data feature introduced in HLF v1.2 by storing reserve price for an item private data-store accessible to only seller org.
- Other data about the item to be sold is visible to all peers of buyer org and seller org in the channel.
- Buyers can publish their bids for items as per the auction period; they can view the current highest bid and raise their bid if they wish
- The seller can perform the auction as per the auction end period for an item.  The item is sold to the highest bidder provided the bid amount is greater than the reserve price quoted by the seller; otherwise the auction is cancelled.
- The application also simulates the payment by maintaining “available balance” in every user profile; on successful auction for an item the bid amount will be transferred from buyer to seller’s “available balance”


## Prerequisites and setup:

* [Docker](https://www.docker.com/products/overview) - v1.12 or higher
* [Docker Compose](https://docs.docker.com/compose/overview/) - v1.8 or higher
* [Git client](https://git-scm.com/downloads) - needed for clone commands
* [Download Docker images using instructions](https://github.com/hyperledger/fabric-samples)
* **Node.js** v8.11.0 or higher
* **HyperLedger Fabric** v1.2 or higher
* **govendor**

***This PoC is developed and tested with HLF v1.2/v1.3, Fabric Node SDK v1.2.0/v1.3.0 and go1.10.3***

## Network configuration
The provisioned HLF v1.2 network consists of
 - 2 orgs – seller(Org1) and buyer(Org2) with 2 peers per org
 - 1 CA per org and
 - Solo Orderer
 - CouchDB would be used as stateDB

### Private Data Collection

- ReservePrice data of every item is part of Org1's (seller) sideDB
- Collection Policy

```
    [{
        "name": "collectionReservePrice",
        "policy": "OR('Org1MSP.member')",
        "requiredPeerCount": 1,
        "maxPeerCount": 2,
        "blockToLive":0
    } ]
```
Please refer to [Private-data Architecture](https://hyperledger-fabric.readthedocs.io/en/latest/private-data-arch.html) for more details

#### This PoC makes use of attribute-based access control hence we need external go packages (cid package)
External packages are listed in vendor.json file in the chaincode directory

Execute following commands to fetch those go pacakges in **Terminal Window 1**
 - add full path for chaincode/ to your $GOPATH
 - cd chaincode/src/auction/
 - govendor sync vendor/vendor.json

More information on govendoring can be found [here](https://github.com/kardianos/govendor)


### Launch the network using following commands
Once govendoring is completed
 - cd network
 - ./network-setup.sh down (optional)
    - removes old containers, unwanted docker images and volumes
 - ./network-setup.sh up
    - Using the configuration from first-network sample, the script
    - creates channel named "mychannel"
    - join the peers from Org1, Org2 to the channel
    - generates anchor peers per org
    - installs and instantiates smart contract

### in **Terminal Window 2**, start Node Server
Install node-modules
 - cd api/
 - npm install

Start node server
  - node app.js (node server is started on Port 4000)


### in **Terminal Window 3**, execute sample REST APIs

1 Register a seller

```
curl -s -X POST http://localhost:4000/auction/users \
-H "content-type: application/json" \
-d '{"username" :"Jim","orgName" :"Org1","password" :"pass","avlBalance" :"1500","currency":"dollars"}'

OUTPUT:

{
    "result": 200,
    "loginid": "Org1-Jim"
}
```

2 Register couple of buyers

```
curl -s -X POST http://localhost:4000/auction/users \
-H "content-type: application/json" \
-d '{"username" :"Sam","orgName" :"Org2","password" :"pass","avlBalance" :"1500","currency":"dollars"}'

curl -s -X POST http://localhost:4000/auction/users \
-H "content-type: application/json" \
-d '{"username" :"Pam","orgName" :"Org2","password" :"pass","avlBalance" :"1500","currency":"dollars"}'
```

3 Login as seller

```
curl -s -X POST http://localhost:4000/auction/login \
-H "content-type: application/json" \
-d '{"loginId":"Org1-Jim",	"password":"pass"}'

OUTPUT:
{
    "token": "<JSON Web Token>",
    "result": 200,
    "loginid": "Org1-Jim"
}
```

4 Create item for auction

datetime format - dd-mm-yyyy hh:mins:secs UTC

```
curl -s -X POST http://localhost:4000/auction/items \
-H "authorization: Bearer <Put JSON Web Token obtained from step 3>" \
-H "content-type: application/json" \
-d '
{
"itemName" :"redmi",
"itemDesc" :"smartphone",
"itemCat" :"electronic",
"currency" :"dollars",
"minBidPrice" :"225",
"reservePrice" :"350",
"auctionStartDt" :"02-11-2018 09:00:00",
"auctionEndDt" :"03-11-2018 09:00:00"
}'


OUTPUT
{
    "result": 200,
    "itemId": "ITEM-70b370238079d05dff7feeee67abb85874f4d860b6527655aaf90b14d44aa848"
}
```
The "reservePrice" data is sent in **transient map** by the Fabric client to the Smart Contract

Please note **itemId is generated dyanmically**; hence you need to save the itemId for further Rest Api calls


5 Login as buyer (Sam)

```
curl -s -X POST http://localhost:4000/auction/login \
-H "content-type: application/json" \
-d '{"loginId":"Org2-Sam",	"password":"pass"}'
```

6 List Items as buyer

```
curl -s -X GET http://localhost:4000/auction/items \
-H "authorization: Bearer <Put JSON Web Token obtained from step 5>" \
-H "content-type: application/json"

OUTPUT:
{
    "result": 200,
    "list": [
        {
            "typeOfObject": "ITEM",
            "itemId": "ITEM-70b370238079d05dff7feeee67abb85874f4d860b6527655aaf90b14d44aa848",
            "name": "redmi",
            "description": "smartphone",
            "category": "electronic",
            "currency": "dollars",
            "minBidPrice": 225,
            "createdOn": "2018-11-02T05:52:00Z",
            "status": "CREATED",
            "owner": "Org1-Jim",
            "creator": "Org1-Jim",
            "auctionStartTime": "02-11-2018 09:00:00",
            "auctionEndTime": "03-11-2018 09:00:00",
            "currHighestBid": 225,
            "reservePrice": ""
        }
    ]
}
```

Note that reservePrice is **NOT** visible to buyer

7 Place bid on item as Sam

```
curl -s -X POST http://localhost:4000/auction/bids \
-H "authorization: Bearer <Put JSON Web Token obtained from step 5>" \
-H "content-type: application/json" \
-d '{
    "itemId" :"<Put the ItemId obtained in step 6>",
    "bidAmount": "360"
    }'

OUTPUT:
{
    "result": 200,
    "bidId": "BID-0bb6207bdf7c5bca1c579d9876da323b660b1862ed9edbc47272bb47a0d76e28"
}
```

The Bid must be higher than minimum Bid price set by seller and the current highest bid placed on the item by other buyer.

8 Login as another buyer (Pam)

```
curl -s -X POST http://localhost:4000/auction/login \
-H "content-type: application/json" \
-d '{"loginId":"Org2-Pam",	"password":"pass"}'
```

9 Place bid on item as Pam

```
curl -s -X POST http://localhost:4000/auction/bids \
-H "authorization: Bearer <Put JSON Web Token obtained from step 8>" \
-H "content-type: application/json" \
-d '{
    "itemId" :"<Put the ItemId obtained in step 6>",
    "bidAmount": "380"
    }'
```

10 Auction item as seller (An item will be auctioned only if auction-end-date for that item has reached)

```
curl -s -X PATCH http://localhost:4000/auction/items \
-H "authorization: Bearer <Put JSON Web Token obtained from step 3>" \
-H "content-type: application/json"
```

The smart contract scans through all the items to check if the auction end date has reached for an item in "CREATED" status.
For such eligible items, the bids are verified against the reserve price set by seller; the item is then sold to the highest bidder.
The smart contract also checks if the highest bidder has sufficient amount in his account to purchase the item; if not the item is sold to next highest bidder.
The auction is cancelled for an item if any of the conditions are not met.

11 List Items as seller (Jim)

```
curl -s -X GET http://localhost:4000/auction/items \
-H "authorization: Bearer <Put JSON Web Token obtained from step 3>" \
-H "content-type: application/json"

OUTPUT:
{
    "result": 200,
    "list": [
        {
            "typeOfObject": "ITEM",
            "itemId": "ITEM-70b370238079d05dff7feeee67abb85874f4d860b6527655aaf90b14d44aa848",
            "name": "redmi",
            "description": "smartphone",
            "category": "electronic",
            "currency": "dollars",
            "minBidPrice": 225,
            "createdOn": "2018-11-02T05:52:00Z",
            "status": "SOLD",
            "owner": "Org2-Pam",
            "creator": "Org1-Jim",
            "auctionStartTime": "02-11-2018 09:00:00",
            "auctionEndTime": "03-11-2018 09:00:00",
            "currHighestBid": 380,
            "reservePrice": "350"
        }
    ]
}
```

Note that reservePrice is visible to seller.
The item is updated after auction API is called
 - status is changed to "SOLD",
 - owner is changed to "Org2-Pam" and
 - currHighestBid is changed to 380


