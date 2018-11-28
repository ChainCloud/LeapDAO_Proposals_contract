pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IBridgeContract.sol";

/**
 * @title BridgeTestable 
 * @dev This is the implementation of IBridgeContract.
 * Uses only for test purposes to emulate bridge
*/
contract BridgeTestable is Ownable, IBridgeContract {
	uint public exitStake;
	uint public epochLength;

	/**
	* @notice This function can be called by owner
	* @param uint _exitStake – value of param exitStake
	*/
	function setExitStake(uint _exitStake) public onlyOwner {
		exitStake = _exitStake;
	}

	/**
	* @notice This function can be called by owner
	* @param uint _exitStake – value of param exitStake
	*/
	function setEpochLength(uint _epochLength) public onlyOwner {
		epochLength = _epochLength;
	}
}