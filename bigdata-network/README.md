# BigData Network

## Purpose
This network is used to understand how to store data when handling thousands of transactions per second which all update a single value in the ledger. Frequently, this sort of application will run into trouble on Fabric as the value will be updated between read-set creation and committing a transaction, causing a validation error and rejecting the transaction. To solve this issue, the frequently updated value is instead stored as a series of deltas which are aggregated when the value must be retrieved. In this way, no single row is frequently read and updated, but rather a collection of rows is considered.

## How
This sample provides the chaincode and scripts required to run a BigData application. For ease of use, it runs on the same network which is brought up by `byfn.sh` in the `first-network` folder within `fabric-samples`, albeit with a few small modifications. The instructions to build the network and run some invocations are provided below.

### Build your network
1. `cd` into the `first-network` folder within `fabric-samples`, e.g. `cd ~/fabric-samples/first-network`
2. Open `docker-compose-cli.yaml` in your favorite editor, and edit the following lines:
  * In the `volumes` section of the `cli` container, edit the second line which refers to the chaincode folder to point to the chaincode folder within the `bigdata-network` folder, e.g.

    `./../chaincode/:/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go` --> 
    `./../bigdata-network/chaincode/:/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go`
  * Again in the `volumes` section, edit the fourth line which refers to the scripts folder so it points to the scripts folder within the `bigdata-network` folder, e.g.

    `./scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/` --> 
    `./../bigdata-network/scripts/:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/`

  * Finally, comment out the `command` section by placing a `#` before it, e.g. `#    command: /bin/bash -c './scripts/script.sh ${CHANNEL_NAME}; sleep $TIMEOUT'`

3. We can now bring our network up by typing in `./byfn.sh -m up -c mychannel`
4. Open a new terminal window and enter the CLI container using `docker exec -it cli bash`, all operations on the network will happen within this container from now on.

### Install and instantiate the chaincode
1. Once you're in the CLI container run `cd scripts` to enter the `scripts` folder
2. Set-up the environment variables by running `source setclienv.sh`
3. Set-up your channels and anchor peers by running `./channel-setup.sh`
4. Install your chaincode by running `./install-chaincode.sh 1.0`. The only argument is a number representing the chaincode version, every time you want to install and upgrade to a new chaincode version simply increment this value by 1 when running the command, e.g. `./install-chaince.sh 2.0`
5. Instantiate your chaincode by running `./instantiate-chaincode.sh 1.0`. The version argument serves the same purpose as in `./install-chaincode.sh 1.0` and should match the version of the chaincode you just installed. In the future, when upgrading the chaincode to a newer version, `./upgrade-chaincode.sh 2.0` should be used instead of `./instantiate-chaincode.sh 1.0`.
6. Your chaincode is now installed and ready to receive invocations

### Invoke the chaincode
All invocations are provided as scripts in `scripts` folder; these are detailed below.

#### Update
The format for update is: `./update-invoke.sh name value operation` where `name` is the name of the variable to update, `value` is the value to add to the variable, and `operation` is either `+` or `-` depending on what type of operation you'd like to add to the variable. In the future, multiply/divide operations will be supported (or add them yourself to the chaincode as an exercise!)

Example: `./update-invoke.sh myvar 100 +`

#### Get
The format for get is: `./get-invoke.sh name` where `name` is the name of the variable to get.

Example: `./get-invoke.sh myvar`

#### Delete
The format for delete is: `./delete-invoke.sh name` where `name` is the name of the variable to delete.

Example: `./delete-invoke.sh myvar`

#### Prune
Pruning takes all the deltas generated for a variable and combines them all into a single row, deleting all previous rows. This helps cleanup the ledger when many updates have been performed. There are two types of pruning: `prunefast` and `prunesafe`. Prune fast performs the deletion and aggregation simultaneously, so if an error happens along the way data integrity is not guaranteed. Prune safe performs the aggregation first, backs up the results, then performs the deletion. This way, if an error occurs along the way, data integrity is maintained.

The format for pruning is: `./[prunesafe|prunefast]-invoke.sh name` where `name` is the name of the variable to prune.

Example: `./prunefast-invoke.sh myvar` or `./prunesafe-invoke.sh myvar`
