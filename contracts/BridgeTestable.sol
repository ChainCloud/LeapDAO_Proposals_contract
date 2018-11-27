pragma solidity ^0.4.24;
import "./IBridgeContract.sol";

contract BridgeTestable {
	uint public exitStake;
	uint public epochLength;

	function setExitStake(uint _exitStake) public  {
		exitStake = _exitStake;
	}

	function setEpochLength(uint _epochLength) public  {
		// epochLength = _epochLength;
	}
}