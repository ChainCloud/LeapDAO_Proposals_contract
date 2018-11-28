pragma solidity ^0.4.24;
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./IBridgeContract.sol";


contract BridgeTestable is Ownable, IBridgeContract {
	uint public exitStake;
	uint public epochLength;

	function setExitStake(uint _exitStake) public onlyOwner {
		exitStake = _exitStake;
	}

	function setEpochLength(uint _epochLength) public onlyOwner {
		epochLength = _epochLength;
	}
}