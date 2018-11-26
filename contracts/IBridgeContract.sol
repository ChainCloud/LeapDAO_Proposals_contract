pragma solidity ^0.4.24;

contract IBridgeContract {
  function setExitStake(uint256 _exitStake) public;

  function setEpochLength(uint256 _epochLength) public;
}