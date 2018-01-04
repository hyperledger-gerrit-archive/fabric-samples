## Build Your First Network (BYFN)

The directions for using this are documented in the Hyperledger Fabric
["Build Your First Network"](http://hyperledger-fabric.readthedocs.io/en/latest/build_network.html) tutorial.

Additionally you can review the options for the script `byfn.sh` with the command

    ./byfn.sh -h

To launch an scenario different from the default (`docker-compose-cli.yaml`) yu can use the `-f` flag as follows:

    # this ones launches the example chaincode with historic query for a KV capabilities. 
    #More info on "chaincode/chaincode_history/README.md" 
    ./byfn.sh -f docker-compose-history.yaml -m up 