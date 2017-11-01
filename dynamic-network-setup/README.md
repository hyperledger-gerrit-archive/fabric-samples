## Dynamic Hyperledger network creation

A sample application which will help the developers to concentrate on working with hyperledger fabric framework without worrying about setting up the whole network.
It will ask you about the number of organisations , no of peers in each organisations ,domain name and channel name and setup the whole network accordingly.



### Prerequisites :

Docker - v1.12 or higher
Docker Compose - v1.8 or higher
Git client - needed for clone commands
A linux machine , the script is for a linux machine.


cd fabric-samples/dynamic-network-setup/

Once you have completed the above setup

just run the bash script with the command:

```
bash generate.sh
```


So if you dont have the cryptogen tool or configtx tool , this script will download it for you.

Crypto material will be  generated using the cryptogen tool from Hyperledger Fabric and mounted to all peers, the orderering node and CA containers. 
An Orderer genesis block (genesis.block) and channel configuration transaction will be  generated using the configtxgen tool from Hyperledger Fabric and placed within the artifacts folder. More details regarding the configtxgen tool are available here.


You can get all the certificates and other material generated inside the 'artifacts' folder , you can copy that to your project and start working with your application.

### Discover Peer Ports

If you want to see the addresses of all the peers and orderers just go to

cd fabric-samples/dynamic-network-setup/artifacts/

There will be a docker-compose.yaml file , from which you can get the addresses needed.


### Note
Please do not change the templates given in the project as generate.sh script will stop working if the lines get changed.

If you want to understand how it is working , you can have a look at the script -  generate.sh


