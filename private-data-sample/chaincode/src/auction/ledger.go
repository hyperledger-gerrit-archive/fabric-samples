/*
* Copyright Persistent Systems 2018. All Rights Reserved.
* SPDX-License-Identifier: Apache-2.0
*/


package main

import(
	"bytes"	
	"time"
	"strconv"
	"encoding/json"	
	"github.com/hyperledger/fabric/core/chaincode/shim"	
	sc "github.com/hyperledger/fabric/protos/peer"
)

/* writeToLedger - Marshals json data into bytes and writes data on ledger against supplied key
*/
func writeToLedger(APIstub shim.ChaincodeStubInterface, ledgerKey string, ledgerData interface{})(bool, error){
	logger.Info("****** writeToLedger ***********")

	//Marshal object data
	ledgerDataAsBytes, err := json.Marshal(ledgerData)
	if err!=nil{
			logger.Error("Error while marshalling the ledgerData object")
			return false, err
	}

	// Put data on ledger
	err = APIstub.PutState(ledgerKey, ledgerDataAsBytes)
	if err!=nil{
			logger.Error("Error while putting Data onto ledger")
			return false, err
	}
	return true, nil
}

func writeToPrivateState(APIstub shim.ChaincodeStubInterface, collectionName string, ledgerKey string, ledgerData interface{})(bool, error){
	logger.Info("****** Entering  ", funcName(), " Args - ", collectionName, ledgerKey, ledgerData,  "***********")

	//Marshal object data
	ledgerDataAsBytes, err := json.Marshal(ledgerData)
	if err!=nil{
		logger.Error("Error while marshalling the ledgerData object")
		return false, err
	}

	// Put data on PrivateState
	err = APIstub.PutPrivateData(collectionName, ledgerKey, ledgerDataAsBytes)
	if err != nil {
		logger.Error("Error while putting Data onto private state :: " + err.Error())
		return false, err
	}

	return true, nil
}

/* readFromLedger - reads data from ledger for supplied key and returns unmarshaled data 
*/
func readFromLedger(APIstub shim.ChaincodeStubInterface, ledgerKey string) (error, []byte){
	logger.Info("****** readFromLedger ***********")

	dataAsBytes, err := APIstub.GetState(ledgerKey)
	if err != nil {
		logger.Error("Error while fetching data for Id - %s from ledger", ledgerKey)
		return NewErrFetchFromLedger("Error while fetching data for Id - "+ ledgerKey +" from ledger"), nil
		
	} else if dataAsBytes == nil {
		logger.Error("Data object for Id (",ledgerKey, ") does not exists")
		return NewErrLedgerKeyMismatch("Data object for Id ("+ledgerKey+ ") does not exists"), nil
	}
	
	return nil, dataAsBytes
}

/* readFromPrivateState - reads data from private state for supplied key and returns unmarshaled data 
*/
func readFromPrivateState(APIstub shim.ChaincodeStubInterface, collectionName string, ledgerKey string) (error, []byte){
	logger.Info("****** readFromPrivateState args ", collectionName, ledgerKey, "***********")
	
	dataAsBytes, err := APIstub.GetPrivateData(collectionName, ledgerKey)

	if err != nil {
		logger.Error("Error while fetching data for Id - %s from private state", ledgerKey)
		return NewErrFetchFromLedger("Error while fetching data for Id - "+ ledgerKey +" from ledger"), nil

	} else if dataAsBytes == nil {
		logger.Error("Data object for Id (",ledgerKey, ") does not exists")
		return NewErrLedgerKeyMismatch("Data object for Id ("+ledgerKey+ ") does not exists"), nil
	}

	return nil, dataAsBytes
}

/* doesKeyExist
*  checks whether the key exists on ledger 
* Return value
*	 true/false
* 	 if true then returns the value in bytes as well
*/
func doesKeyExist(APIstub shim.ChaincodeStubInterface, key string)(bool,[]byte){
	logger.Info("****** doesKeyExist ("+ key +")***********")

	// Check if object exists with given key	
	dataAsBytes, err := APIstub.GetState(key)
	if err != nil {
		logger.Error("Error while fetching data for Id - %s from ledger", key)
		return false, nil
		
	} else if dataAsBytes == nil {
		logger.Error("Data object for Id (",key, ") does not exists")
		return false, nil
	}

	return true, dataAsBytes
}

/*
 * getQueryResultForQueryString
 * Executes the passed in query string on CouchDB.
 * Result set is built and returned as a byte array containing the JSON results
 * Input Parameters:
 * 		APIstub shim.ChaincodeStubInterface, 
 *		queryString string, 
 *		resultType string - single(to fetch single record) / multiple(to fetch multiple records)
 * Return Value:
 *		buffer.bytes 
*/
func getQueryResultForQueryString(APIstub shim.ChaincodeStubInterface, queryString string, resultType string) ([]byte, error) {
    logger.Info("****** getQueryResultForQueryString ***********")
    logger.Info("queryString: ", queryString)

    resultsIterator, err := APIstub.GetQueryResult(queryString)
    if err != nil {
		return nil, err
    }
    defer resultsIterator.Close()

    // buffer is a JSON array containing QueryRecords
	var buffer bytes.Buffer
	if resultType == configObj.QryResultType.Multiple	{
		buffer.WriteString("[")
	}

    bArrayMemberAlreadyWritten := false
    for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
				
		if resultType == configObj.QryResultType.Multiple	{
			buffer.WriteString("{\"Key\":")
			buffer.WriteString("\"")
			buffer.WriteString(queryResponse.Key)
			buffer.WriteString("\"")
			buffer.WriteString(", \"Record\":")
		}
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		if resultType == configObj.QryResultType.Multiple	{
			buffer.WriteString("}")
		}
		bArrayMemberAlreadyWritten = true
	}
	if resultType == configObj.QryResultType.Multiple	{
		buffer.WriteString("]")
	}

    logger.Info("- getQueryResultForQueryString queryResult:\n\n", buffer.String())

    return buffer.Bytes(), nil
}


/* getAccessHistory - fetch history of transactions for supplied ledger Key
   input value - ledgerKey
   output value - array of transactions
*/
func GetHistoryForKey(APIstub shim.ChaincodeStubInterface, args[]string)sc.Response{
	
		logger.Info("****** getHistoryForKey ***********")
		
		ledgerKey := args[0]
	
		resultsIterator, err := APIstub.GetHistoryForKey(ledgerKey)
		if err != nil {
			return shim.Error(err.Error())
		}
		defer resultsIterator.Close()
	
		logger.Info("Fetched data from ledger for ", ledgerKey)
	
		// buffer is a JSON array containing historic values for the marble
		var buffer bytes.Buffer
		buffer.WriteString("[")
	
		bArrayMemberAlreadyWritten := false
		for resultsIterator.HasNext() {
			response, err := resultsIterator.Next()
			if err != nil {
				return shim.Error(err.Error())
			}
			// Add a comma before array members, suppress it for the first array member
			if bArrayMemberAlreadyWritten == true {
				buffer.WriteString(",")
			}
			buffer.WriteString("{\"TxId\":")
			buffer.WriteString("\"")
			buffer.WriteString(response.TxId)
			buffer.WriteString("\"")
	
			buffer.WriteString(", \"Value\":")
			// if it was a delete operation on given key, then we need to set the
			//corresponding value null. Else, we will write the response.Value as-is 
			if response.IsDelete {
				buffer.WriteString("null")
			} else {
				buffer.WriteString(string(response.Value))
			}
	
			buffer.WriteString(", \"Timestamp\":")
			buffer.WriteString("\"")
			buffer.WriteString(time.Unix(response.Timestamp.Seconds, int64(response.Timestamp.Nanos)).String())
			buffer.WriteString("\"")
	
			buffer.WriteString(", \"IsDelete\":")
			buffer.WriteString("\"")
			buffer.WriteString(strconv.FormatBool(response.IsDelete))
			buffer.WriteString("\"")
	
			buffer.WriteString("}")
			bArrayMemberAlreadyWritten = true
		}
		buffer.WriteString("]")
	
		logger.Info("Data from ledger::", buffer.String())
		return shim.Success(buffer.Bytes())
	}
