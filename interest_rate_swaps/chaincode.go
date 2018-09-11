/*
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
*/

package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/hyperledger/fabric/core/chaincode/shim/ext/statebased"
	pb "github.com/hyperledger/fabric/protos/peer"
)

/* InterestRateSwap represents an interest rate swap on the ledger
 * The swap is active between its start- and end-date.
 * At the specified interval, two parties A and B exchange the following payments:
 * A->B PrincipalAmount * FixedRate
 * B->A PrincipalAmount * (ReferenceRate + FloatingRate)
 */
type InterestRateSwap struct {
	StartDate       time.Time
	EndDate         time.Time
	PaymentInterval time.Duration
	PrincipalAmount uint64
	FixedRate       uint64
	FloatingRate    uint64
	ReferenceRate   string
}

/*
SwapManager is the chaincode that handles interest rate swaps.
The chaincode endorsement policy includes an auditing organization.
It provides the following functions:
-) createSwap: create swap with participants
-) calculatePayment: calculate what needs to be paid
-) settlePayment: mark payment done
-) setReferenceRate: for providers to set the reference rate

The SwapManager stores three different kinds of information on the ledger:
-) the actual swap data ("swap" + ID)
-) the payment information ("payment" + ID), if nil, the payment has been settled
-) the reference rate ("rr" + ID)
*/
type SwapManager struct {
}

// Init callback
func (cc *SwapManager) Init(stub shim.ChaincodeStubInterface) pb.Response {
	// set the limit above which the auditor needs to be involved
	err := stub.PutState("audit_limit", stub.GetArgs()[1])
	if err != nil {
		return shim.Error(err.Error())
	}

	// create the LIBOR reference rate, require it to be endorsed by LSE
	rrID := "rr" + "libor"
	err = stub.PutState(rrID, nil)
	if err != nil {
		return shim.Error(err.Error())
	}
	ep, err := statebased.NewStateEP(nil)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = ep.AddOrgs(statebased.RoleTypePeer, "LSE")
	if err != nil {
		return shim.Error(err.Error())
	}
	epBytes, err := ep.Policy()
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.SetStateValidationParameter(rrID, epBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte{})
}

// Invoke dispatcher
func (cc *SwapManager) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	funcName, _ := stub.GetFunctionAndParameters()
	if function, ok := functions[funcName]; ok {
		return function(stub)
	}
	return shim.Error(fmt.Sprintf("Unknown function %s", funcName))
}

var functions = map[string]func(stub shim.ChaincodeStubInterface) pb.Response{
	"createSwap":       createSwap,
	"calculatePayment": calculatePayment,
	"settlePayment":    settlePayment,
	"setReferenceRate": setReferenceRate,
}

// Create a new swap among participants.
// The new swap needs to be endorsed by its participants and potentially the auditor.
// Parameters: swap ID + a JSONized InterestRateSwap + 2 participants
func createSwap(stub shim.ChaincodeStubInterface) pb.Response {
	_, parameters := stub.GetFunctionAndParameters()
	if len(parameters) != 4 {
		return shim.Error("Wrong number of arguments supplied")
	}

	// create the swap
	swapID := "swap" + string(parameters[0])
	irsJSON := []byte(parameters[1])
	var irs InterestRateSwap
	err := json.Unmarshal(irsJSON, &irs)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.PutState(swapID, irsJSON)
	if err != nil {
		return shim.Error(err.Error())
	}

	// get the auditing threshold
	auditLimit, err := stub.GetState("audit_limit")
	if err != nil {
		return shim.Error(err.Error())
	}
	threshold, err := strconv.Atoi(string(auditLimit))
	if err != nil {
		return shim.Error(err.Error())
	}

	// set endorsers
	ep, err := statebased.NewStateEP(nil)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = ep.AddOrgs(statebased.RoleTypePeer, parameters[2], parameters[3])
	if err != nil {
		return shim.Error(err.Error())
	}
	// if the swap principal amount exceeds $1M, the auditor needs to endorse as well
	if irs.PrincipalAmount > uint64(threshold) {
		err = ep.AddOrgs(statebased.RoleTypePeer, "auditor")
		if err != nil {
			return shim.Error(err.Error())
		}
	}

	// set the endorsement policy for the swap
	epBytes, err := ep.Policy()
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.SetStateValidationParameter(swapID, epBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	// create and set the key for the payment
	paymentID := "payment" + string(parameters[0])
	err = stub.PutState(paymentID, nil)
	if err != nil {
		return shim.Error(err.Error())
	}
	err = stub.SetStateValidationParameter(paymentID, epBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte{})
}

// Calculate the payment due for a given swap
func calculatePayment(stub shim.ChaincodeStubInterface) pb.Response {
	_, parameters := stub.GetFunctionAndParameters()
	if len(parameters) != 1 {
		return shim.Error("Wrong number of arguments supplied")
	}

	// retrieve swap
	swapID := "swap" + string(parameters[0])
	irsJSON, err := stub.GetState(swapID)
	if err != nil {
		return shim.Error(err.Error())
	}
	if irsJSON == nil {
		return shim.Error("Swap does not exist")
	}
	var irs InterestRateSwap
	err = json.Unmarshal(irsJSON, &irs)
	if err != nil {
		return shim.Error(err.Error())
	}

	// check if the previous payment has been settled
	paymentID := "payment" + string(parameters[0])
	paid, err := stub.GetState(paymentID)
	if err != nil {
		return shim.Error(err.Error())
	}
	if paid != nil {
		return shim.Error("Previous payment has not been settled yet")
	}

	// get reference rate
	referenceRateString, err := stub.GetState("rr" + irs.ReferenceRate)
	if err != nil {
		return shim.Error(err.Error())
	}
	if referenceRateString == nil {
		return shim.Error("Reference rate not found")
	}
	referenceRate, err := strconv.Atoi(string(referenceRateString))
	if err != nil {
		return shim.Error(err.Error())
	}

	// calculate payment
	p1 := int(irs.PrincipalAmount * irs.FixedRate)
	p2 := int(irs.PrincipalAmount * (irs.FloatingRate + uint64(referenceRate)))
	payment := strconv.Itoa(p1 - p2)
	err = stub.PutState(paymentID, []byte(payment))
	if err != nil {
		return shim.Error(err.Error())
	}

	return shim.Success([]byte{})
}

// Settle the payment for a given swap
func settlePayment(stub shim.ChaincodeStubInterface) pb.Response {
	_, parameters := stub.GetFunctionAndParameters()
	if len(parameters) != 1 {
		return shim.Error("Wrong number of arguments supplied")
	}
	paymentID := "payment" + string(parameters[0])
	err := stub.PutState(paymentID, nil)
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success([]byte{})
}

// Set the reference rate for a given rate provider
func setReferenceRate(stub shim.ChaincodeStubInterface) pb.Response {
	_, parameters := stub.GetFunctionAndParameters()
	if len(parameters) != 2 {
		return shim.Error("Wrong number of arguments supplied")
	}

	rrID := "rr" + string(parameters[0])
	err := stub.PutState(rrID, []byte(parameters[1]))
	if err != nil {
		return shim.Error(err.Error())
	}
	return shim.Success([]byte{})
}
