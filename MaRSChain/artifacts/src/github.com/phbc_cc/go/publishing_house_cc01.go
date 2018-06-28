/*

 Copyright TCS Ltd 2018 All Rights Reserved.

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
*/

package main

import (
    "encoding/json"
    "fmt"
    "strings"
    "bytes"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.com/hyperledger/fabric/protos/peer"
)

/***** Data Structures *****/

type PublishingHousesChaincode struct {
}

/* Custom data model -- defined data models required for PublishingHousesDataModel chaincode */
type publishingHousesDetails struct {
     ObjectType             string   `json:"docType"`       //docType is used to distinguish the various types of objects in state database
     PaperID                string   `json:"paperID"`
     ProgramChairID         string   `json:"programChairID"`
     ManuscriptStatus       string   `json:"manuscriptStatus"`
}

/***** Interface functions (chaincode entry points) *****/
func (t *PublishingHousesChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
    fmt.Println("Init called. Entering PublishingHousesChaincode application")

    return shim.Success(nil)
}

/* Invoke - entry point for API Invocations */
func (t *PublishingHousesChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
    function, args := stub.GetFunctionAndParameters()
    fmt.Println("invoke is running " + function)

    // Handle different functions
    if function == "add_paper" {
        return t.add_paper(stub, args)
    } else if function == "queryPaperInfo" {
        return t.queryPaperInfo(stub, args)
    } else if function == "update_paper" {
        return t.update_paper(stub, args)
    } else if function == "queryAllPapers" {
        return t.queryAllPapers(stub, args)
    } else if function == "queryPaperStatus" {
        return t.queryPaperStatus(stub, args)
    }
    fmt.Println("invoke did not find func: " + function)
    return shim.Error("Received unknown function invocation")
}


/***** APIs implementation *****/

/* Papers submitted by Programchair (in conference blockchain) will be added to publishing house bc */
func (t *PublishingHousesChaincode) add_paper(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    fmt.Println("add_paper() to Publishinghouse blockchain (PHBC)")

    // ==== Input arguments ====
    if len(args) != 3 {
        fmt.Println("Incorrect number of arguments. Expecting 3")
        return shim.Error(jsonify("Error", "Incorrect number of arguments. Expecting 3"))
    }

    // ==== Input sanitation ====
    fmt.Println("- add_paper input sanitation")
    if len(args[0]) <= 0 {
        return shim.Error(jsonify("Error", "1st argument must be a non-empty string"))
    }
    if len(args[1]) <= 0 {
        return shim.Error(jsonify("Error", "2nd argument must be a non-empty string"))
    }
    if len(args[2]) <= 0 {
        return shim.Error(jsonify("Error", "3rd argument must be a non-empty string"))
    }

    paperID := strings.ToLower(args[0])
    manuscriptStatus  := strings.ToLower(args[1])
    programChairID   := strings.ToLower(args[2])

    // === read manuscripts details from state ===
    paperIDAsBytes, err := stub.GetState(paperID)
    if err != nil {
        return shim.Error(jsonify("Error", "Failed to fetch state for [" + paperID + "]"))
    } else if paperIDAsBytes != nil {
        fmt.Println("This paperID already exists")
        return shim.Error(jsonify("Error", "Given key [" + paperID + "] already exist"))
    }

    // ==== Create publishingHousesDetails object and marshal to JSON ====
    objectType := "publishingHousesDetails"
    publishingHousesDetails := &publishingHousesDetails{objectType, paperID, programChairID, manuscriptStatus}
    paperJSONasBytes, err := json.Marshal(publishingHousesDetails)
    if err != nil {
        return shim.Error(jsonify("Error", err.Error()))
    }

    // === Save PaperSubmissionInfo details to state database===
    err = stub.PutState(paperID, paperJSONasBytes)
    if err != nil {
        return shim.Error(jsonify("Error", err.Error()))
    }

    fmt.Println("- end add_paper")
    return shim.Success(nil)
}


/* To get manuscript information from PHBC state*/
func (t *PublishingHousesChaincode) queryPaperInfo(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    var err error

    if len(args) != 1 {
        return shim.Error(jsonify("Error", "Incorrect number of arguments. Expecting 1"))
    }

    if len(args[0]) <= 0 {
        return shim.Error(jsonify("Error", "1st argument must be a non-empty string"))
    }
    paperID := args[0]

    // === get author paper submission details from chaincode state ===
    valAsbytes, err := stub.GetState(paperID)
    if err != nil {
        return shim.Error(jsonify("Error", "Failed to fetch state for [" + paperID + "]"))
    } else if valAsbytes == nil {
        return shim.Error(jsonify("Error", "Given key [" + paperID + "] does not exist."))
    }

    fmt.Println("-end queryPaperInfo")
    return shim.Success(valAsbytes)
}


/* To get status of manuscript from PHBC chaincode state */
func (t *PublishingHousesChaincode) queryPaperStatus(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var err error

    if len(args) != 1 {
        return shim.Error(jsonify("Error", "Incorrect number of arguments. Expecting 1"))
    }

    if len(args[0]) <= 0 {
        return shim.Error(jsonify("Error", "1st argument must be a non-empty string"))
    }
    paperID := args[0]

    // === get author paper submission details from chaincode state ===
    valAsbytes, err := stub.GetState(paperID)
    if err != nil {
        return shim.Error(jsonify("Error", "Failed to fetch state for [" + paperID + "]"))
    } else if valAsbytes == nil {
        return shim.Error(jsonify("Error", "Given key [" + paperID + "] does not exist."))
    }

    getStatusList := publishingHousesDetails{}
    err = json.Unmarshal(valAsbytes, &getStatusList)
    if err != nil {
        return shim.Error(jsonify("Error", err.Error()))
    }

    paperstatus := getStatusList.ManuscriptStatus

    fmt.Println("- end queryPaperStatus")
    return shim.Success([]byte(paperstatus))
}

/* To update existing paper details in publishing houses blockchain.
** Once review window is closed, conference blockchain consolidates all the reviews of manuscipts
** and result(paper status) will be updated to publishing houses blockchain.
*/
func (t *PublishingHousesChaincode) update_paper(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    // ==== Input arguments ====
    if len(args) != 2 {
        return shim.Error(jsonify("Error", "Incorrect number of arguments. Expecting 2"))
    }

    // ==== Input sanitation ====
    fmt.Println("- update_paper()")
    if len(args[0]) <= 0 {
        return shim.Error(jsonify("Error", "1st argument must be a non-empty string"))
    }
    if len(args[1]) <= 0 {
        return shim.Error(jsonify("Error", "2nd argument must be a non-empty string"))
    }

    paperID := args[0]
    status  := args[1]

    // === read manuscript details from state ===
    paperIDAsBytes, err := stub.GetState(paperID)
    if err != nil {
        return shim.Error(jsonify("Error", "Failed to fetch state for [" + paperID + "]"))
    } else if paperIDAsBytes == nil {
        return shim.Error(jsonify("Error", "Given key [" + paperID + "] does not exist."))
    }

    updateStatusList := publishingHousesDetails{}
    err = json.Unmarshal(paperIDAsBytes, &updateStatusList)
    if err != nil {
        return shim.Error(jsonify("Error", err.Error()))
    }

    updateStatusList.ManuscriptStatus = status //Update status

    updateStatusListJSONasBytes, _ := json.Marshal(updateStatusList)
    err = stub.PutState(paperID, updateStatusListJSONasBytes) //rewrite the paperID
    if err != nil {
        return shim.Error(jsonify("Error", err.Error()))
    }

    fmt.Println("- end update_paper()")
    return shim.Success(nil)
}

/* To query all existing manuscript details in publishing houses blockchain */
func (t *PublishingHousesChaincode) queryAllPapers(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    queryString := fmt.Sprintf("{\"selector\":{\"docType\":\"publishingHousesDetails\"}}")

    queryResults, err := getQueryResultForQueryString(stub, queryString)
    if err != nil {
        return shim.Error(jsonify("Error", err.Error()))
    }

   return shim.Success(queryResults)
}


/***** Supporting functions *****/

/* This function is derived from the one in the Hyperledger Project's "fabric-samples" repository.
 *
 * getQueryResultForQueryString executes the passed in query string.
 * Result set is built and returned as a byte array containing the JSON results.
 */
func getQueryResultForQueryString(stub shim.ChaincodeStubInterface, queryString string) ([]byte, error) {

    fmt.Printf("- getQueryResultForQueryString queryString:\n%s\n", queryString)

    resultsIterator, err := stub.GetQueryResult(queryString)
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    // buffer is a JSON array containing QueryRecords
    var buffer bytes.Buffer
    buffer.WriteString("[")

    bArrayMemberAlreadyWritten := false
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next() //updated to v1.0.0

        if err != nil {
            return nil, err
        }

        // Add a comma before array members, suppress it for the first array member
        if bArrayMemberAlreadyWritten == true {
            buffer.WriteString(",")
        }

        buffer.WriteString("{\"Key\":")
        buffer.WriteString("\"")
        buffer.WriteString(queryResponse.Key)
        buffer.WriteString("\"")

        buffer.WriteString(", \"Record\":")

        // Record is a JSON object, so we write as-is
        buffer.WriteString(string(queryResponse.Value))
        buffer.WriteString("}")
        bArrayMemberAlreadyWritten = true
    }

    buffer.WriteString("]")

    fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

   return buffer.Bytes(), nil
}


func jsonify(key string, message string) (string) {
    return "{\"" + key + "\":\"" + message + "\"}"
}

/***** Main function *****/
func main() {
    err := shim.Start(new(PublishingHousesChaincode))
    if err != nil {
        fmt.Printf("Error starting Publishinghouses blockchain chaincode: %s", err)
    }
}

