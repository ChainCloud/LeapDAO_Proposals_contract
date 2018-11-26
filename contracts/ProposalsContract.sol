pragma solidity ^0.4.24;

import "@thetta/core/contracts/tokens/PreserveBalancesOnTransferToken.sol";
import "@thetta/core/contracts/tokens/SnapshotToken.sol";

import "./IBridgeContract.sol";


// See https://github.com/leapdao/leap-contracts/blob/master/contracts/LeapBridge.sol
// _bridgeContract should call transferOwnership() to THIS contract!!!
contract ProposalsContract {
	IBridgeContract bridgeContract;
	PreserveBalancesOnTransferToken token;

	uint QUORUM_PERCENT = 80;
	uint CONSENSUS_PERCENT = 80;

	event VotingStarted(string _type, uint _param, address _byWhom);

	enum VotingType {
		SetExitStake,
		SetEpochLength
	}

	struct Voting {
		address startedBy;
		VotingType votingType;
		uint param;
		SnapshotToken snapshot;
		uint pro;
		uint versus;
	}

	Voting[] votings;

	constructor(IBridgeContract _bridgeContract, PreserveBalancesOnTransferToken _token) public {
		bridgeContract = _bridgeContract;
		token = _token;
	}

	function setExitStake(uint256 _exitStake) public {
		votings.push(Voting(
			msg.sender,       // startedBy
			VotingType.SetExitStake, // votingType
			_exitStake,       // param
			SnapshotToken(token.createNewSnapshot()), // snapshot
			0, 			   // pro
			0)); 		   // versus
		
		emit VotingStarted("setExitStake", _exitStake, msg.sender);
	}

	function setEpochLength(uint256 _epochLength) public {
		votings.push(Voting(		
			msg.sender,       // startedBy
			VotingType.SetEpochLength, // votingType
			_epochLength,     // param
			SnapshotToken(token.createNewSnapshot()), // snapshot
			0, 			   // pro
			0)); 		   // versus
		
		emit VotingStarted("setEpochLength", _epochLength, msg.sender);
	}

	function getVotingsCount()public view returns(uint){
		return votings.length;
	}

	function getVoting(uint _i) public view returns(VotingType votingType, uint paramValue, address startedBy) {
		votingType	  = votings[_i].votingType;
		paramValue  = votings[_i].param;
		startedBy   = votings[_i].startedBy;
	}

	function getVotingStats(uint _i) public view returns(uint pro, uint versus, bool isFinished, bool isResultYes) {
		pro           = votings[_i].pro;
		versus        = votings[_i].versus;
		isFinished    = _isFinished(_i);
		isResultYes   = _isResultYes(_i);
	}

	function _isFinished(uint _i) internal view returns(bool isFin) {
		isFin = ((votings[_i].pro * QUORUM_PERCENT) > votings[_i].snapshot.totalSupply());
	}

	function _isResultYes(uint _i) internal view returns(bool isYes) {
		isYes = (votings[_i].versus <= ((1-CONSENSUS_PERCENT)*votings[_i].pro));
	}

	function vote(uint _i, bool _isYes) public {
		require(!_isFinished(_i));
		uint tokenHolderBalance = votings[_i].snapshot.balanceOf(msg.sender);

		// 1 - recalculate stats
		if(_isResultYes(_i)){
			votings[_i].pro += tokenHolderBalance;
		}else{
			votings[_i].versus += tokenHolderBalance;
		}
		
		// 2 - if voting is finished (last caller) AND the result is YES -> call the target method 
		if(_isFinished(_i) && _isResultYes(_i)){
			if(votings[_i].votingType==VotingType.SetExitStake){
				bridgeContract.setExitStake(votings[_i].param);
			}else if(votings[_i].votingType==VotingType.SetEpochLength) {
				bridgeContract.setEpochLength(votings[_i].param);
			}

			token.stopSnapshot(votings[_i].snapshot);
		}
	}
}
