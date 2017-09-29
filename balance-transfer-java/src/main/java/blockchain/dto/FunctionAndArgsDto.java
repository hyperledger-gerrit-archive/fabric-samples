/*
 * Mindtree Ltd.
 */

package blockchain.dto;

/**
 * @author SWATI RAJ
 *
 */
public class FunctionAndArgsDto {
	
	private String chaincodeName;
	String function;
	String[] args;
	public String getFunction() {
		return function;
	}
	public void setFunction(String function) {
		this.function = function;
	}
	public String[] getArgs() {
		return args;
	}
	public void setArgs(String[] args) {
		this.args = args;
	} 

	public String getChaincodeName() {
		return chaincodeName;
	}

	public void setChaincodeName(String chaincodeName) {
		this.chaincodeName = chaincodeName;
	}
	

}
