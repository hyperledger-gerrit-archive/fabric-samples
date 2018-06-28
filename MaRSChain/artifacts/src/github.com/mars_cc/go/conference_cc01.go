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
    "strconv"
    "bytes"

    "github.com/hyperledger/fabric/core/chaincode/shim"
    pb "github.com/hyperledger/fabric/protos/peer"
)

type ReviewSystemChaincode struct {
}

// Custom data model -- defined data models required for PaperReviewInfo chaincode
type paperInfo struct {
     ObjectType             string   `json:"docType"`       //docType is used to distinguish the various types of objects in state database
     PaperID                string   `json:"paperID"`
     AuthorName         [3] string   `json:"authorName"`
     ManuscriptStatus       string   `json:"manuscriptStatus"`
     ManuscriptAuthors      string   `json:"manuscriptAuthors"`
     ProgramChairID         string   `json:"programChairID"`
     ReviewersList      [3] string   `json:"reviewersList"`
     ReviewersDecision  [3] string   `json:"reviewersDecision"`
     PublicationResult      string   `json:"publicationResult"`
}

// ===================================================================
// Init initializes chaincode --
// ===================================================================
func (t *ReviewSystemChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
    fmt.Println("Manuscript Review System Application")
    fmt.Println("Entering chaincode Init()")
    return shim.Success(nil)
}

// ====================================================
// submit_paper - Authors submit paper to program chair
// ====================================================
func (t *ReviewSystemChaincode) submit_paper(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    fmt.Println("Entering chaincode submit_paper()")

    // ==== Input arguments ====
    if len(args) != 4 {
        return shim.Error("Incorrect number of arguments. Expecting 4")
    }

    var authorName [3]string
    var reviewersList [3]string
    var reviewersDecision [3]string

    // ==== Input sanitation ====
    fmt.Println("- Submit_papers input sanitation")
    if len(args[0]) <= 0 { //author1
        return shim.Error("1st argument must be a non-empty string")
    }
    if len(args[1]) <= 0 { //author2
        return shim.Error("2nd argument must be a non-empty string")
    }
    if len(args[2]) <= 0 { //author3
        return shim.Error("3rd argument must be a non-empty string")
    }
    if len(args[3]) <= 0 { //author paper attachement //TODO
        return shim.Error("4th argument must be a non-empty string")
    }

    authorName[0] = strings.ToLower(args[0])
    authorName[1] = strings.ToLower(args[1])
    authorName[2] = strings.ToLower(args[2])

    manuscriptAuthors := strings.ToLower(args[3])
    manuscriptStatus  := "under-submission"
    paperID := "paper_" + manuscriptAuthors
    programChairID := "NA"
    reviewersList[0] = "NA"
    reviewersList[1] = "NA"
    reviewersList[2] = "NA"
    reviewersDecision[0] = "NA"
    reviewersDecision[1] = "NA"
    reviewersDecision[2] = "NA"
    publicationResult  := "NA"

    // ==== Check if paperID already exists ====
    paperIDAsBytes, err := stub.GetState(paperID)
    if err != nil {
        return shim.Error("Failed to get paperID: " + err.Error())
    } else if paperIDAsBytes != nil {
        fmt.Println("This paperID already exists: " + paperID)
        return shim.Error("This paperID already exists: " + paperID)
    }

    // ==== Create paperInfo object and marshal to JSON ====
    objectType := "paperInfo"
    paperInfo := &paperInfo{objectType, paperID, authorName, manuscriptStatus, manuscriptAuthors, programChairID, reviewersList, reviewersDecision, publicationResult}

    paperJSONasBytes, err := json.Marshal(paperInfo)
    if err != nil {
        return shim.Error(err.Error())
    }

    // === Save PaperSubmissionInfo details to state database===
    err = stub.PutState(paperID, paperJSONasBytes)
    if err != nil {
        return shim.Error(err.Error())
    }

    // ==== user details saved and indexed. Return success ====
    fmt.Println("- end submit_paper")
    return shim.Success(nil)
}

// ================================================================================
// querySubmittedPaperInfo - get paper submission details of the user from chaincode state
// ================================================================================
func (t *ReviewSystemChaincode) querySubmittedPaperInfo(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var jsonResp string
    var err error

    if len(args) != 1 {
        return shim.Error("Incorrect number of arguments. Expecting paperID to query")
    }

    if len(args[0]) <= 0 { //paper_ID
        return shim.Error("1st argument must be a non-empty string")
    }
    paperID := args[0]

    // === get author paper submission details from chaincode state ===
    valAsbytes, err := stub.GetState(paperID)
    if err != nil {
        jsonResp = "{\"Error\":\"Failed to get state for " + paperID + "\"}"
        return shim.Error(jsonResp)
    } else if valAsbytes == nil {
        jsonResp = "{\"Error\":\"paperID does not exist: " + paperID + "\"}"
        return shim.Error(jsonResp)
    }

    return shim.Success(valAsbytes)
}

// ================================================================================
// update_paper - Program chair(PC) updates tx status from under-submission to submitted
// once double submission of papers is validated
// ================================================================================
func (t *ReviewSystemChaincode) update_paper(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    fmt.Println("Entering chaincode update_paper()")

    // ==== Input arguments ====
    if len(args) != 2 {
        return shim.Error("Incorrect number of arguments. Expecting 4")
    }

    // ==== Input sanitation ====
    fmt.Println("- update_paper input sanitation")
    if len(args[0]) <= 0 { //paper_ID
        return shim.Error("1st argument must be a non-empty string")
    }
    if len(args[1]) <= 0 { //tx status
        return shim.Error("2nd argument must be a non-empty string")
    }

    paperID := args[0]
    manuscriptStatus  := args[1]

    paperIDAsBytes, err := stub.GetState(paperID)
    if err != nil {
        return shim.Error("Failed to get paperID:" + err.Error())
    } else if paperIDAsBytes == nil {
        return shim.Error("paperID does not exist")
    }

    updateTxStatus := paperInfo{}
    err = json.Unmarshal(paperIDAsBytes, &updateTxStatus) //unmarshal it aka JSON.parse()
    if err != nil {
        return shim.Error(err.Error())
    }

    updateTxStatus.ManuscriptStatus = manuscriptStatus //Update transaction type

    updateTxStatusJSONasBytes, _ := json.Marshal(updateTxStatus)
    err = stub.PutState(paperID, updateTxStatusJSONasBytes) //rewrite the paperID
    if err != nil {
        return shim.Error(err.Error())
    }

    fmt.Println("- end update_paper")
    return shim.Success(nil)
}

// ================================================================================
// assign_reviewers - Program chair(PC) assigns reviewers for the submitted papers.
// Assigning reviewers decision will be taken offline by all the PCs.
// Final reviewers list will be submitted by PC and stored in the state database.
// ================================================================================
func (t *ReviewSystemChaincode) assign_reviewers(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    fmt.Println("Entering chaincode assign_reviewers()")

    var reviewersList [3]string

    // ==== Input arguments ====
    if len(args) != 4 {
        return shim.Error("Incorrect number of arguments. Expecting 4")
    }

    // ==== Input sanitation ====
    fmt.Println("- assign_reviewers input sanitation")
    if len(args[0]) <= 0 { //paper_ID
        return shim.Error("1st argument must be a non-empty string")
    }
    if len(args[1]) <= 0 { //reviewer1
        return shim.Error("2nd argument must be a non-empty string")
    }
    if len(args[2]) <= 0 { //reviewer2
        return shim.Error("3rd argument must be a non-empty string")
    }
    if len(args[3]) <= 0 { //reviewer3
        return shim.Error("4th argument must be a non-empty string")
    }

    programChairID := "pc_01"
    //paperID := strings.ToLower(args[0])
    paperID := args[0]
    reviewersList[0] = strings.ToLower(args[1])
    reviewersList[1] = strings.ToLower(args[2])
    reviewersList[2] = strings.ToLower(args[3])
    manuscriptStatus  := "under-review"

    paperIDAsBytes, err := stub.GetState(paperID)
    if err != nil {
        return shim.Error("Failed to get paperID:" + err.Error())
    } else if paperIDAsBytes == nil {
        return shim.Error("paperID does not exist")
    }

    updateReviewersList := paperInfo{}
    err = json.Unmarshal(paperIDAsBytes, &updateReviewersList) //unmarshal it aka JSON.parse()
    if err != nil {
        return shim.Error(err.Error())
    }

    if (updateReviewersList.ManuscriptStatus == "submitted") {
        fmt.Println("assign reviewers for papers ")
        updateReviewersList.ReviewersList = reviewersList      //update assigned reviewers details in existing field
        updateReviewersList.ManuscriptStatus = manuscriptStatus //Update transaction type
        updateReviewersList.ProgramChairID = programChairID  //Update programChairID

        updateReviewersListJSONasBytes, _ := json.Marshal(updateReviewersList)
        err = stub.PutState(paperID, updateReviewersListJSONasBytes) //rewrite the paperID
        if err != nil {
            return shim.Error(err.Error())
        }
    } else {
        fmt.Println("cannot assign reviewers for rejected papers (double/concurrent) submissions")
    }

    // ==== assign_reviewers details saved and indexed. Return success ====
    fmt.Println("- end assign_reviewers")
    return shim.Success(nil)
}

// ================================================================================
// get_reviewers_decision - Reviewers update paper score for the assigned papers.
// ================================================================================
func (t *ReviewSystemChaincode) get_reviewers_decision(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    fmt.Println("Entering chaincode get_reviewers_decision()")

    var reviewersDecision string
    var reviewerName string

    // ==== Input arguments ====
    if len(args) != 3 {
        return shim.Error("Incorrect number of arguments. Expecting 3")
    }

    // ==== Input sanitation ====
    fmt.Println("- get_reviewers_decision input sanitation")
    if len(args[0]) <= 0 { //reviewer name
        return shim.Error("1st argument must be a non-empty string")
    }
    if len(args[1]) <= 0 { //paper id
        return shim.Error("2nd argument must be a non-empty string")
    }
    if len(args[2]) <= 0 { //rating(or)score
        return shim.Error("3rd argument must be a non-empty string")
    }

    paperID := args[1]
    reviewerName = args[0]
    reviewersDecision = args[2]

    paperIDAsBytes, err := stub.GetState(paperID)
    if err != nil {
        return shim.Error("Failed to get paperID:" + err.Error())
    } else if paperIDAsBytes == nil {
        return shim.Error("paperID does not exist")
    }

    updateReviewersList := paperInfo{}
    err = json.Unmarshal(paperIDAsBytes, &updateReviewersList) //unmarshal it aka JSON.parse()
    if err != nil {
        return shim.Error(err.Error())
    }

    reviewerIndex := -1
    if updateReviewersList.ReviewersList[0] == reviewerName {
        reviewerIndex = 0
    } else if updateReviewersList.ReviewersList[1] == reviewerName {
        reviewerIndex = 1
    } else if updateReviewersList.ReviewersList[2] == reviewerName {
        reviewerIndex = 2
    }
    if reviewerIndex != -1 {
        updateReviewersList.ReviewersDecision[reviewerIndex] = reviewersDecision  // Update reviewers decision details in its field
        fmt.Println("Updated ReviewersList[" + string(reviewerIndex) + "]")
    } else {
        fmt.Println("Not authorised to submit your reviews for given paper " + paperID)
        fmt.Println("ReviewersList not updated")
        return shim.Error("Reviewer " + reviewerName + " is not authorised to submit reviews for paper " + paperID)
    }

    updateReviewersListJSONasBytes, _ := json.Marshal(updateReviewersList)
    err = stub.PutState(paperID, updateReviewersListJSONasBytes) //rewrite the paperID
    if err != nil {
        return shim.Error(err.Error())
    }

    fmt.Println("- end get_reviewers_decision")
    return shim.Success(nil)
}

// =====================================================================================
// make_decision - Calculating overall score based on assigned reviewers' scores
// ======================================================================================
func (t *ReviewSystemChaincode) make_decision(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    var paper_final_score int

    queryString := fmt.Sprintf("{\"selector\":{\"docType\":\"paperInfo\"}}")

    resultsIterator, err := stub.GetQueryResult(queryString)
    if err != nil {
        return shim.Error("Failed to get paperID:" + err.Error())
    }
    defer resultsIterator.Close()

    for resultsIterator.HasNext() {

        //queryResultKey, _, err := resultsIterator.Next()
        queryResponse, err := resultsIterator.Next() //updated to v1.0.0
        if err != nil {
            return shim.Error("Failed to get paperID:" + err.Error())
        }

        //paperID := queryResultKey
        paperID := queryResponse.Key
        fmt.Println("- start make_decision", paperID)

        scoreAsBytes, err := stub.GetState(paperID)
        if err != nil {
            return shim.Error("Failed to get paperID:" + err.Error())
        } else if scoreAsBytes == nil {
            return shim.Error("paperID does not exist")
        }

        paperScore := paperInfo{}
        err = json.Unmarshal(scoreAsBytes, &paperScore) //unmarshal it aka JSON.parse()
        if err != nil {
            return shim.Error(err.Error())
        }

        if paperScore.ManuscriptStatus == "under-review" {

            reviewers_val0, _ := strconv.Atoi(string(paperScore.ReviewersDecision[0]))
            reviewers_val1, _ := strconv.Atoi(string(paperScore.ReviewersDecision[1]))
            reviewers_val2, _ := strconv.Atoi(string(paperScore.ReviewersDecision[2]))

            paper_final_score =  (reviewers_val0 + reviewers_val1 + reviewers_val2)/3

            if paper_final_score > 2 {
                fmt.Println("paper_final _scrore **********", paper_final_score)
                manuscriptStatus  := "accepted"
                paperScore.ManuscriptStatus = manuscriptStatus
            } else {
                fmt.Println("paper_final _scrore **********", paper_final_score)
                manuscriptStatus  := "rejected"
                paperScore.ManuscriptStatus = manuscriptStatus
            }

            // === change reviewersDecision (default value NA) to calculated values ===
            paperScore.PublicationResult = strconv.Itoa(paper_final_score)   // Updated paper_final_score details in its field

            userJSONasBytes, _ := json.Marshal(paperScore)

            // === rewrite the user details ===
            err = stub.PutState(paperID, userJSONasBytes)
            if err != nil {
                return shim.Error(err.Error())
            }
        }
    }
    fmt.Println("- end make_decision(success)")
    return shim.Success(nil)
}

// =============================================================================
// queryAllPaperIDs - To query all existing paper details in conference blockchain
// ==============================================================================
func (t *ReviewSystemChaincode) queryAllPaperIDs(stub shim.ChaincodeStubInterface, args []string) pb.Response {

    queryString := fmt.Sprintf("{\"selector\":{\"docType\":\"paperInfo\"}}")

    queryResults, err := getQueryResultForQueryString(stub, queryString)
    if err != nil {
        return shim.Error(err.Error())
    }
    return shim.Success(queryResults)
}

/* This function is derived from the one in the Hyperledger Project's "fabric-samples" repository. */
// =========================================================================================
// getQueryResultForQueryString executes the passed in query string.
// Result set is built and returned as a byte array containing the JSON results.
// =========================================================================================
func getQueryResultForQueryString(stub shim.ChaincodeStubInterface, queryString string) ([]byte, error) {

    fmt.Printf("- getQueryResultForQueryString queryString:\n%s\n", queryString)

    resultsIterator, err := stub.GetQueryResult(queryString)
    if err != nil {
        return nil, err
    }
    defer resultsIterator.Close()

    // buffer is a JSON array containing QueryRecords
    var buffer bytes.Buffer

    bArrayMemberAlreadyWritten := false
    for resultsIterator.HasNext() {
        queryResponse, err := resultsIterator.Next() //updated to v1.0.0

        if err != nil {
            return nil, err
        }
        // Add a space before array members, suppress it for the first array member
        if bArrayMemberAlreadyWritten == true {
            buffer.WriteString(" ")
        }
        buffer.WriteString(queryResponse.Key) //updated to v1.0.0
        bArrayMemberAlreadyWritten = true
    }

    fmt.Printf("- getQueryResultForQueryString queryResult:\n%s\n", buffer.String())

    return buffer.Bytes(), nil
}

// =============================================================
// queryPaperStatus - get status of paper from chaincode state
// =============================================================
func (t *ReviewSystemChaincode) queryPaperStatus(stub shim.ChaincodeStubInterface, args []string) pb.Response {
    var jsonResp string
    var err error
    fmt.Println("--------- Entering chaincode queryPaperStatus()")
    if len(args) != 1 {
        return shim.Error("Incorrect number of arguments. Expecting paperID to query")
    }

    if len(args[0]) <= 0 { //paper_ID
        return shim.Error("1st argument must be a non-empty string")
    }
    paperID := args[0]

    // === get author paper submission details from chaincode state ===
    valAsbytes, err := stub.GetState(paperID)
    if err != nil {
        jsonResp = "{\"Error\":\"Failed to get state for " + paperID + "\"}"
        return shim.Error(jsonResp)
    } else if valAsbytes == nil {
        jsonResp = "{\"Error\":\"paperID does not exist: " + paperID + "\"}"
        return shim.Error(jsonResp)
    }

    getStatusList := paperInfo{}
    err = json.Unmarshal(valAsbytes, &getStatusList) //unmarshal it aka JSON.parse()
    if err != nil {
        return shim.Error(err.Error())
    }

    paperstatus := getStatusList.ManuscriptStatus //get status

    fmt.Println("--------- end queryPaperStatus")
    return shim.Success([]byte(paperstatus))
}



// Invoke - Our entry point for Invocations
// ========================================
func (t *ReviewSystemChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
    function, args := stub.GetFunctionAndParameters()
    fmt.Println("invoke is running " + function)

    // Handle different functions
    if function == "submit_paper" { // author submit papers
        return t.submit_paper(stub, args)
    } else if function == "update_paper" { //update paper status from under-submission to submitted //Double submission validation checking
        return t.update_paper(stub, args)
    } else if function == "querySubmittedPaperInfo" { //get submitted paper info by querying using paper ID
        return t.querySubmittedPaperInfo(stub, args)
    } else if function == "assign_reviewers" { //program chair assign papers to set of reviewers
        return t.assign_reviewers(stub, args)
    } else if function == "get_reviewers_decision" { //collect reviewers decision
        return t.get_reviewers_decision(stub, args)
    } else if function == "make_decision" { //make decision based on all reviewers' decision
                return t.make_decision(stub, args)
    } else if function == "queryAllPaperIDs" { //queryAllPaper
                return t.queryAllPaperIDs(stub, args)
    } else if function == "queryPaperStatus" { //query papers status from statedb
        return t.queryPaperStatus(stub, args)
    }

    fmt.Println("invoke did not find func: " + function) //error
    return shim.Error("Received unknown function invocation")
}

// ===================================================================================
// Main
// ===================================================================================
func main() {
    err := shim.Start(new(ReviewSystemChaincode))
    if err != nil {
        fmt.Printf("Error starting Simple chaincode: %s", err)
    }
}

