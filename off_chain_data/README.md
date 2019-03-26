# Block event listener

The blockchain event listener is a Node.js application to demonstrate listening
for block events from a specified channel. This sample will demonstrates how you
can use the [Peer channel-based event services](https://hyperledger-fabric.readthedocs.io/en/master/peer_event_services.html)
to replicate data to an off chain database. An off chain database allows you to
analyze the data from your network or build a dashboard without degrading the
performance of your application.

This sample uses the [ChannelEventHub](https://fabric-sdk-node.github.io/master/ChannelEventHub.html) from the Node.JS Fabric SDK to write data to local instance of CouchDB.

## Getting Started

The Blockchain event listener uses code similar to the `fabcar` example to
connect from the Node SDK to a network created using the `basic-network` sample.

### Install dependencies

You will need to install version 8.9.x of Node.js and download the application
dependencies. Execute the following command to install all required packages
from the `event_listener` directory.

```
cd fabric-samples/event_listener
npm install
```

### Configuration

The configuration for the listener is stored in config.json:

```
    {
        "peer_name": "peer0.org1.example.com",
        "channelid": "mychannel",
        "use_couchdb":false,
        "couchdb_address": "http://localhost:5990"
    }
```

`peer_name:` is the target peer for the listener
`channelid:`  channel name for block events
`use_couchdb:` If set to true, events will be stored in a local instance of
CouchDB. If set to false, only a local log of events will be stored.
`couchdb_address:` is the local address for an off chain CouchDB database.

### Creating a CouchDB Offchain Data Store

If you wish to create a local CouchDB container to store block information in an
offline data store, create set the "use_couchdb" option to true in config.json,
and create the database using the commands below.

The following commands will create a CouchDB container on port 5990 and start
the container:
```
docker run --publish 5990:5984 --detach --name offchaindb hyperledger/fabric-couchdb
docker start offchaindb
```

### Starting the Network

Use the following command to start a simple network with the marbles02 chaincode
deployed:

```
./startFabric.sh
```

This command creates a fabric network with 1 peer, an ordering service, and a
channel named `mychannel`.

### Starting the Channel Event Listener

Once the network is started, we can use the Node.js SDK to create the users and
certificates our application will use to interact with the network. Use the
following commands to enroll the admin user and register `user1`:

```
node enrollAdmin.js
node registerUser.js
```

Use the follwing command to start the block event listener:

```
node blockEventListener.js
```

The block event listener will log events received to the console and write event
blocks to a log file based on the channelid and chaincode name.

In this example, blockEventListener.js creates a listener named "offchain-listener" on 
the blockchain network.  The listener adds each block received to a processing map called
BlockMap for temporary storage and ordering purposes.  BlockProcessing.js runs as a
daemon and pulls each block in order from the BlockMap and extracts the keys and values and
stores the resulting data to CouchDB.

The event listener stores the next block to retrieve in a file named
nextblock.txt. This file is automatically created and initialized to zero if it
does not exist.

The channel event listener will record entries to a log file defined as
channelid_chaincodeid.log In this example, events will be written to
mychannel_marbles.log.

If use_couchdb is set to true, two tables will be created for each chaincode.
The first is a table defined by the channelid and chaincodeid.  In this example, 
this table is named mychannel_marbles. This table is an offline representation 
of the world state.

A second table based on the channelid and chaincodeid and appended with 'history'
is also created. In this example, the table is named mychannel_marbles_history
and records each block as a historical record entry.

Both tables are useful tools in extracting summary information as well as checking historical
changes.

### Generate data on the blockchain

Now that our listener is setup, we can generate data using the marbles chaincode
and use our application to replicate the data to CouchDB. Open a new terminal
and navigate to the `fabric-samples/event_listener` directory.

You can use the `addMarbles.js` file to add random sample data to blockchain.
The file uses the configuration information stored in `addMarbles.json` to
create a series of marbles. This file will be created during the first execution
of the utility if it does not exist. The utility can be run multiple times
without changing the properties. The nextMarbleNumber will be incremented and
stored in the JSON file.

```
    {
        "nextMarbleNumber": 100,
        "numberMarblesToAdd": 20
    }
```

Run the following command to add 20 marbles to the blockchain:

```
node addMarbles.js
```    

After the marbles have been added to the ledger, use the following command to
transfer one of the marbles to a new owner:

```
node transferMarble.js marble110 james
```

Now run the following command to delete the marble that was transferred:

```
node deleteMarble.js marble110
```

### Offchain CouchDB storage:

An offchain CouchDB is used in this example to store the values captured by the block listener.

Each distinct channel and contract name will create a table in the offchain database.  For example,
the contract "marbles" on channel "mychannel" will create the tablename "mychannel_marbles" in the
offchain database.  This will store the value from block based on key value from the block.  The
CouchDB will be a close approximation to the world state in Fabric.  

A separate history table will also be created which will store the key, value, datetime and a flag
indicating if the key has been deleted.  The naming will be tablename with "history" appended.  
For example, the history for "mychannel_marbles" would be "mychannel_marbles_history".

Additional indexes and views may be applied to the offchain database to enable summary data or historical
information to be extracted more efficiently.  The following sections will create views and indexes
as well as showing example CouchDB queries for extracting summary data.


### Configure a map/reduce view for summarizing counts of marbles by color:

Open a new terminal window and execute the following:
```
curl -X PUT http://127.0.0.1:5990/mychannel_marbles/_design/colorviewdesign -d '{"views":{"colorview":{"map":"function (doc) { emit(doc.color, 1);}","reduce":"function ( keys , values , combine ) {return sum( values )}"}}}' -H 'Content-Type:application/json'
```

Execute a query to retrieve the total number of marbles (reduce function):
```
curl -X GET http://127.0.0.1:5990/mychannel_marbles/_design/colorviewdesign/_view/colorview?reduce=true
```
If this successful, this command will return the number of marbles in the
blockchain world state, without having to query the blockchain ledger:
```
{"rows":[
  {"key":null,"value":19}
  ]}
```

Execute a query to retrieve the number of marbles by color (map function):

```
curl -X GET http://127.0.0.1:5990/mychannel_marbles/_design/colorviewdesign/_view/colorview?group=true
```

The command will return a the list of marbles by color from the couchDB database.

```
{"rows":[
  {"key":"blue","value":2},
  {"key":"green","value":2},
  {"key":"purple","value":3},
  {"key":"red","value":4},
  {"key":"white","value":6},
  {"key":"yellow","value":2}
  ]}
```

Create an index to support retrieving history.  Execute the following command:
```
curl -X POST http://127.0.0.1:5990/mychannel_marbles_history/_index -d '{"index":{"fields":["blocknumber", "sequence", "key"]},"name":"marble_history"}'  -H 'Content-Type:application/json'
```

Execute a query to retrieve the history for marble110:
```
curl -X POST http://127.0.0.1:5990/mychannel_marbles_history/_find -d '{"selector":{"key":{"$eq":"marble110"}}, "fields":["blocknumber","is_delete","value"],"sort":[{"blocknumber":"asc"}, {"sequence":"asc"}]}'  -H 'Content-Type:application/json'
```

You should see the history of the marble that was transferred and then deleted.
```
{"docs":[
{"blocknumber":12,"is_delete":false,"value":"{\"docType\":\"marble\",\"name\":\"marble110\",\"color\":\"blue\",\"size\":60,\"owner\":\"debra\"}"},
{"blocknumber":22,"is_delete":false,"value":"{\"docType\":\"marble\",\"name\":\"marble110\",\"color\":\"blue\",\"size\":60,\"owner\":\"james\"}"},
{"blocknumber":23,"is_delete":true,"value":""}
  ]}
```


## Clean up

If you are finished using the sample application, you can bring down the network
and any accompanying artifacts.

* Change to `fabric-samples/basic-network` directory
* To stop the network, run `./stop.sh`
* To completely remove all incriminating evidence of the network, run `./teardown.sh`
