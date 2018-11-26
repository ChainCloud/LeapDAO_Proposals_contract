pragma solidity ^0.4.24;
import "./IBridgeContract.sol";

contract BridgeTestable is IBridgeContract {
	address owner;
	uint public exitStake;
	uint public epochLength;

	modifier onlyOwner() {
		require(msg.sender==owner);
		_;
	}

	constructor() {
		owner = msg.sender;
	}

	function setExitStake(uint256 _exitStake) public onlyOwner {
		exitStake = _exitStake;
	}

	function setEpochLength(uint256 _epochLength) public onlyOwner {
		epochLength = _epochLength;
	}
}