rm -rf /var/hyperledger/*
ORDERER_GENERAL_GENESISPROFILE=SampleSingleMSPSolo orderer
Window 2 - start peer
---------------------
CORE_PEER_ADDRESS=127.0.0.1:7051 peer node start --peer-chaincodedev=true
Windor 3 - start chaincode
--------------------------
cd examples/chaincode/go/chaincode_example02
go build
CORE_PEER_ADDRESS=127.0.0.1:7051 CORE_CHAINCODE_ID_NAME=mycc:0 ./chaincode_example02
Window 4 - create channel and send CC commands
----------------------------------------------
configtxgen -channelID myc -outputCreateChannelTx myc.tx -profile SampleSingleMSPChannel
peer channel create -c myc -f myc.tx -o 127.0.0.1:7050
peer channel join -b myc.block
peer chaincode install -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -n mycc -v 0
CORE_PEER_ADDRESS=127.0.0.1:7051 peer chaincode instantiate -n mycc -v 0 -c '{"Args":["init", "a", "100", "b", "200"]}' -C myc -o 127.0.0.1:7050
CORE_PEER_ADDRESS=127.0.0.1:7051 peer chaincode invoke -n mycc -c '{"Args":["invoke", "a", "b", "10"]}' -C myc -o 127.0.0.1:7050
CORE_PEER_ADDRESS=127.0.0.1:7051 peer chaincode query -n mycc -c '{"Args":["query", "a"]}' -C myc -o 127.0.0.1:7050
