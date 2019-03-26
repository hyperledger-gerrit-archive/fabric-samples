## Block Event Listener

### Purpose

The Blockchain Event Listener is a nodejs application to demonstrate listening for block
events from a specified channel. This will facilitate applications that need an offchain
datastore for managing customer dashboards and summary data.

The Blockchain Event Listener code borrows much of it's setup and configuration from the
fabcar example.

### Getting Started

Configuration is stored in config.json:

    {
        "peer_name": "peer0.org1.example.com",
        "channelid": "mychannel",
        "use_couchdb":false,
        "couchdb_address": "http://localhost:5990"
    }

peer_name:  target peer for the listener
channelid:  channel name for block events
use_couchdb:  if set to true, events will be stored in a local couchdb
couchdb_address:  local address for an off chain couchdb database

Note:  If use_couchdb is set to false, only a local log of events will be stored.


### Creating a CouchDB Offchain Data Store

If you wish to create a couchdb container to store block information in an offline
data store, create the database with the folling paragraph and set the "use_couchdb"
option to true in config.json.

The following commands will create a couchdb container on port 5990 and start the container:

    $ docker run --publish 5990:5984 --detach --name offchaindb hyperledger/fabric-couchdb
    $ docker start offchaindb

### Install Required Packages

    Execute the following command to install all required packages:
      npm install

### Starting the Network

The example starts a simple network and deploys the marbles02 example chaincode.

To start the network open a terminal in the event-listener directory and enter the following:

    $ ./startFabric.sh

This will start the network with one peer using the channel 'mychannel' and deploy the marbles02 chaincode.


### Starting the Channel Event Listener

Open a new terminal and change to the event-listener directory.

Use the fabcar utilities to enroll the admin and register 'user1':

    $ node enrollAdmin.js
    $ node registerUser.js

Start the block event listener:

    $ node blockEventListener.js

The block event listener will log events received to the console and write event blocks to
a log file based on the channelid and chaincode name.

The event listener stores the next block to retrieve in a file named nextblock.txt.  This file
is automatically created and initialized to zero if it does not exist.

The channel event listener will record entries to a log file defined as channelid_chaincodeid.log
In this example, events will be written to mychannel_marbles.log.

If use_couchdb is set to true, two tables will be created for each chaincode.  The first is a table
defined by the channelid and chaincodeid.  In this example, this table is named mychannel_marbles.
This table is an offline representation of the world state.

A second table based on the channelid and chaincodeid and appended with 'history' is also created.
In this example, the table is named mychannel_marbles_history and records each block as a
historical record entry.

Both tables are useful tools in extracting summary information as well as checking historical
changes.


### Testing the Channel Event Listener

Additional utilities are provided to create sample data (see the individual headers for more
information):  

##### addMarbles.js

addMarbles.js will add random sample data to blockchain.

    $ node addMarbles.js

addMarbles will add 10 marbles by default with a starting marble name of "marble100".
Additional marbles will be added by incrementing the number at the end of the marble name.

The properties for adding marbles are stored in addMarbles.json.  This file will be created
during the first execution of the utility if it does not exist.  The utility can be run
multiple times without changing the properties.  The nextMarbleNumber will be incremented and
stored in the JSON file.

    {
        "nextMarbleNumber": 100,
        "numberMarblesToAdd": 10
    }


##### transferMarble.js

tranferMarble.js will transfer ownership a specified marble to a new ownder. Example:

    $ node transferMarble.js marble102 jimmy

##### deleteMarble.js

deleteMarble.js will delete a specified marble. Example:

    $ node deleteMarble.js marble100


### Putting it all together

This section assumes you are going to use CouchDB as the offchain database and the following
sections above have been completed:

- Creating a CouchDB Offchain Data Store
- Starting the Network
- Starting the Channel Event Listener


##### Create Sample Data

Open a new terminal

Change to the event-listener directory

Run the following command twice (this will add 20 marbles):

    $ node addMarbles.js

Run the following to update a marble:

    $ node transferMarble.js marble110 james  

Run the following to delete a marble:

    $ node deleteMarble.js marble110

##### Configure a map/reduce view for summarizing counts of marbles by color:

Open a new terminal window and execute the following:

    $ curl -X PUT http://127.0.0.1:5990/mychannel_marbles/_design/colorviewdesign -d '{"views":{"colorview":{"map":"function (doc) { emit(doc.color, 1);}","reduce":"function ( keys , values , combine ) {return sum( values )}"}}}' -H 'Content-Type:application/json'

Execute a query to retrieve the total number of marbles (reduce function):

    $ curl -X GET http://127.0.0.1:5990/mychannel_marbles/_design/colorviewdesign/_view/colorview?reduce=true

    {"rows":[
    {"key":null,"value":19}
    ]}

Execute a query to retrieve the number of marbles by color (map function):

    $ curl -X GET http://127.0.0.1:5990/mychannel_marbles/_design/colorviewdesign/_view/colorview?group=true

    {"rows":[
    {"key":"blue","value":2},
    {"key":"green","value":2},
    {"key":"purple","value":3},
    {"key":"red","value":4},
    {"key":"white","value":6},
    {"key":"yellow","value":2}
    ]}


Create an index to support retrieving history.  Execute the following command:

    curl -X POST http://127.0.0.1:5990/mychannel_marbles_history/_index -d '{"index":{"fields":["blocknumber", "sequence", "key"]},"name":"marble_history"}'  -H 'Content-Type:application/json'


Execute a query to retrieve the history for marble110:

    curl -X POST http://127.0.0.1:5990/mychannel_marbles_history/_find -d '{"selector":{"key":{"$eq":"marble110"}}, "fields":["blocknumber","is_delete","value"],"sort":[{"blocknumber":"asc"}, {"sequence":"asc"}]}'  -H 'Content-Type:application/json'

    {"docs":[
    {"blocknumber":12,"is_delete":false,"value":"{\"docType\":\"marble\",\"name\":\"marble110\",\"color\":\"blue\",\"size\":60,\"owner\":\"debra\"}"},
    {"blocknumber":22,"is_delete":false,"value":"{\"docType\":\"marble\",\"name\":\"marble110\",\"color\":\"blue\",\"size\":60,\"owner\":\"james\"}"},
    {"blocknumber":23,"is_delete":true,"value":""}
    ]}
