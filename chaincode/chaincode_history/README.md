# Chaincode History

This chaincode intends to demostrate the capabilities to directly query the hitorical values of the KV persisted on Fabric's state database.

Esentially this chaincode is the same as chaincode_exampl02 but including and aditional function called `queryHistory` with returns all the values that the passed key has had since its initialization. This functionality is possible thanks to the function `stub.GetHistoryForKey(<key>)` that returns and iterable object containing all the values ( see `chaincode_history.go` line 200 ).

