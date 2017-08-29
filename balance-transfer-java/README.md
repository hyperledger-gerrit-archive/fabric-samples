

This is an example project (Balance transfer application) where Hyperledger Java SDK is used to create a basic hyperledger 1.0 application

This example is made by using Hyperledger-java-sdk and the integration tests provided in that. We are using sdkintegration classes and sample chaincode from the Hyperledger-java-sdk as it is to connect with the sdk.

## Sample Application

A sample Java Springboot app to demonstrate **__fabric-client__** & **__fabric-ca-client__** Java SDK APIs

### Prerequisites and setup:

* [Docker](https://www.docker.com/products/overview) - v1.12 or higher
* Download docker images
* Java 8
* spring boot dependencies download


```
cd java-hyperledger_v1_sample/src/main/java/sdkintegration
docker-compose -f artifacts/docker-compose.yaml pull
```

Once you have completed the above setup, you will have provisioned a local network with the following docker container configuration:

* 1 CA
* A SOLO orderer
* 2 peers (2 peers in Org1)

#### Artifacts
* Crypto material has been generated using the **cryptogen** tool from Hyperledger Fabric and mounted to all peers, the orderering node and CA containers. More details regarding the cryptogen tool are available [here](http://hyperledger-fabric.readthedocs.io/en/latest/build_network.html#crypto-generator).
* An Orderer genesis block (genesis.block) and channel configuration transaction (mychannel.tx) has been pre generated using the **configtxgen** tool from Hyperledger Fabric and placed within the artifacts folder. More details regarding the configtxgen tool are available [here](http://hyperledger-fabric.readthedocs.io/en/latest/build_network.html#configuration-transaction-generator).

## Running the sample program


##### Terminal Window 1

* Launch the network using docker-compose

```
docker-compose -f artifacts/docker-compose.yaml up

run the spring boot application (By default it runs on port 8080)  the main folder is in blockchain.main package, named start.java , run it as java application.
```
##### Terminal Window 2

* Execute the REST APIs 


```

## Sample REST APIs Requests

### Login Request

* Register and enroll new users 

curl -X POST --header 'Content-Type: application/json' --header 'Accept: text/plain' -d '{
  "username": "Swati Raj"
}' 'http://localhost:8080/enroll'

**OUTPUT:**

```
User jim Enrolled Successfuly  jwt:eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJqeSIsInJvbGVzIjoidXNlciIsImlhdCI6MTUwMjM0NTg2N30.PpzdDNe1lln8s2eyeCEGzd0pTpLv1PxvHfNIMqWBhRQ
```


### Create Channel request

```
curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJzdHJpbmciLCJyb2xlcyI6InVzZXIiLCJpYXQiOjE1MDIzNDczNzJ9.htq7072LZvA3YUbe9acuX6ZGs0LPskF0-NEUSf20L6M' 'http://localhost:8080/api/construct'

```

Please note that the Header **authorization** must contain the JWT returned from the `POST /enroll` call
and by default I am taking m102 as channel name that I am hardcoded in service implementation and the m102.tx file is stored in e2e-Orgs, so you can generate ner channel.tx file by using cryptogen tool and change the channel name


### Recreate Channel request
curl -X PUT --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJzdHJpbmciLCJyb2xlcyI6InVzZXIiLCJpYXQiOjE1MDIzNDczNzJ9.htq7072LZvA3YUbe9acuX6ZGs0LPskF0-NEUSf20L6M' 'http://localhost:8080/api/reconstruct'

please note that if you create a channel once , you cannot recreate the same channel again, you can recreate it if you want to use it anywhere.


### Install chaincode

```
curl -X POST --header 'Content-Type: application/json' --header 'Accept: text/plain' --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJzdHJpbmciLCJyb2xlcyI6InVzZXIiLCJpYXQiOjE1MDIzNDczNzJ9.htq7072LZvA3YUbe9acuX6ZGs0LPskF0-NEUSf20L6M' -d '{
  "chaincodeName": "mycc"
}' 'http://localhost:8080/api/install'
```

### Instantiate chaincode

```
curl -X POST --header 'Content-Type: application/json' --header 'Accept: */*' --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJzdHJpbmciLCJyb2xlcyI6InVzZXIiLCJpYXQiOjE1MDIzNDczNzJ9.htq7072LZvA3YUbe9acuX6ZGs0LPskF0-NEUSf20L6M' -d '{
  "args": [
    "a", "500", "b", "200"
  ],
  "chaincodeName": "mycc",
  "function": "init"
}' 'http://localhost:8080/api/instantiate'
```

### Invoke request

```
curl -X POST --header 'Content-Type: application/json' --header 'Accept: */*' --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJzdHJpbmciLCJyb2xlcyI6InVzZXIiLCJpYXQiOjE1MDIzNDczNzJ9.htq7072LZvA3YUbe9acuX6ZGs0LPskF0-NEUSf20L6M' -d '{
  "args": [
    "move", "a", "b", "100"
  ],
  "chaincodeName": "mycc",
  "function": "invoke"
}' 'http://localhost:8080/api/invoke'
```


### Chaincode Query

```
curl -X GET --header 'Accept: text/plain' --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJzdHJpbmciLCJyb2xlcyI6InVzZXIiLCJpYXQiOjE1MDM5MjM0OTd9.WeTEouNaLhXLaBSjEggc53k2bxh4iKdLw5YKZDdHA10' 'http://localhost:8080/api/query?ChaincodeName=tt1&function=invoke&args=query%2Cb'


```

You can directly send the api requests through swagger which is integrated with this spring boot application
Access the link http://localhost:8080/swagger-ui.html after running the application.


### All the properties are stored in config.properties and hyperledger.properties file, if you want to change any file location or other properties, change it from there.



