## Fabric CA sample

This sample demonstrates the following:
1) How to use the fabric CA server and client to register and enroll orderers, peers,
   administrators, and users.  All private keys are generated in the container in which they are used
   and so is intended to be a close-to-real-world example.
2) How to use Attribute-Based Access Control (ABAC). See fabric-samples/chaincode/abac/abac.go and
   note the use of the "github.com/hyperledger/fabric/core/chaincode/shim/client" package to extract
   attributes from the invoker's identity.  Only identity's with the "abac.init" attribute value of
   "true" can successfully call the "Init" function to instantiate the chaincode.

To setup this sample, run the "setup.sh" script.  This needs to be done only once unless you change fabric or fabric-ca code.

To run this sample, run the "start.sh" script.  You may do this multiple times in a row as needed.

To stop the containers, run ``stop.sh``

<a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>
