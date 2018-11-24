pragma solidity ^0.4.22;

import "./PreserveBalancesOnTransferToken.sol";
import "./SnapshotToken.sol";

import "./IBridgeContract.sol";

// See https://github.com/leapdao/leap-contracts/blob/master/contracts/LeapBridge.sol
// _bridgeContract should call transferOwnership() to THIS contract!!!

contract ProosalsContract {
	IBridgeContract bridgeContract;
	PreserveBalancesOnTransferToken token;

	uint QUORUM_PERCENT = 80;
	uint CONSENSUS_PERCENT = 80;

	event VotingStarted(string _type, uint _param, address _byWhom);

	struct Voting {
		address startedBy;
		string votingType;
		uint param;
		SnapshotToken snapshot;

		uint pro;
		uint versus;
	};

	uint votingCount;
	mapping(uint=>Voting) votings; // votingNumber => voting

	constructor(IBridgeContract _bridgeContract, PreserveBalancesOnTransferToken _token) public {
		bridgeContract = _bridgeContract;
		token = _token;
	}

	function setExitStake(uint256 _exitStake) public {
		votings[votingCount] = Voting(
			token.createNewSnapshot(),
			msg.sender,
			"setExitStake",
			_exitStake,
			0,
			0);
		votingCount++;

		VotingStarted("setExitStake", _exitStake, msg.sender);
	}

	function setEpochLength(uint256 _epochLength) public {
		votings[votingCount] = Voting(
			token.createNewSnapshot(),
			msg.sender,
			"setEpochLength",
			_exitStake,
			0,
			0);
		votingCount++;

		VotingStarted("setEpochLength", _epochLength, msg.sender);
	}

	function getVotingsCount()public view returns(uint){
		return votingCount;
	}

	// TODO: add more vars in returns()?
	function getVoting(uint _i) public view returns(string paramName, uint value, uint dateStarted, address startedBy) {
		paramName	  = votings[_i].paramName;
		value 	  = votings[_i].value;
		dateStarted = votings[_i].dateStarted;
		startedBy   = votings[_i].startedBy;
	}

	// TODO: add more vars in returns()?
	function getVotingStats(uint _i) public view returns(uint pro, uint versus, bool isFinished, bool currentResult) {
		pro           = votings[_i].pro;
		versus        = votings[_i].versus;
		isFinished    = _isFinished(_i);
		currentResult = _isResultYes(_i);
	}

	function _isFinished(uint _i) internal view returns(bool isFin) {
		if((votings[_i].pro * QUORUM_PERCENT) > votings[_i].snapshotToken.totalSupply()) {
			isFin = true;
		}
	}

	function _isResultYes(uint _i) internal view returns(bool isYes) {
		if(votings[_i] <= (1-CONSENSUS_PERCENT)*votings[_i].pro) {
			isYes = true;
		}
	}

	function vote(uint _i, bool _isYes) public {
		require(!_isFinished(_i));
		uint tokenHolderBalance = votings[_i].snapshotToken.balanceOf(msg.sender);

		// 1 - recalculate stats
		if(!isVotingFinished){
			if(_isYes){
				v.pro+=tokenHolderBalance;
			}else{
				v.versus+=tokenHolderBalance;
			}
		}

		// 2 - if voting is finished (last caller) AND the result is YES -> call the target method 
		if(_isFinished(_i) && _isResultYes(_i)){
			if(votings[_i].type=="setExitStake"){
				bridgeContract.setExitStake(v.param);
			}else if(votings[_i].type=="setEpochLength") {
				bridgeContract.setEpochLength(v.param);
			}

			token.stopSnapshot(votings[_i].snapshotToken);
		}
	}
}
