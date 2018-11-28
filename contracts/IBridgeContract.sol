pragma solidity ^0.4.24;


/**
 * @title IBridgeTestable 
 * Used only for test purposes to emulate bridge contract
 */
contract IBridgeContract {
	function setExitStake(uint256 _exitStake) public;

	function setEpochLength(uint256 _epochLength) public;
}
