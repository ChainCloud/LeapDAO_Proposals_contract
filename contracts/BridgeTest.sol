pragma solidity ^0.4.25;
import "./IBridgeContract.sol";

contract BridgeTest is IBridgeContract {
	address owner;

	modifier onlyOwner() {
		require(msg.sender==owner);
		_
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