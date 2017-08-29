/*
 * Mindtree Ltd.
 */

package blockchain.service;

import org.hyperledger.fabric.sdk.Channel;
import org.json.JSONArray;
import org.json.JSONObject;
import org.hyperledger.fabric.sdk.BlockEvent.TransactionEvent;

import blockchain.config.Org;
import blockchain.config.HyperUser;

/**
 * 
 * @author SWATI RAJ
 *
 */

/**
 * 
 * Interface for all the chaincode services that is implemented by
 * Chaincode_Service_Impl class
 *
 */
public interface ChaincodeService {

	public Channel reconstructChannel() throws Exception;

	public String enrollAndRegister(String uname);

	public Channel constructChannel() throws Exception;

	public String installChaincode(String chaincodeName);

	public String instantiateChaincode(String chaincodeName, String chaincodeFunction, String[] chaincodeArgs);

	public String invokeChaincode(String name, String chaincodeFunction, String[] chaincodeArgs);

	public String queryChaincode(String name, String chaincodeFunction, String[] chaincodeArgs);

	public void blockchainInfo(Org sampleOrg, Channel channel);

}
