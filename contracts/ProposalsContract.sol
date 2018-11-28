pragma solidity ^0.4.24;

import "@thetta/core/contracts/tokens/PreserveBalancesOnTransferToken.sol";
import "@thetta/core/contracts/tokens/SnapshotToken.sol";

import "./BridgeTestable.sol";


// See https://github.com/leapdao/leap-contracts/blob/master/contracts/LeapBridge.sol
// _bridgeAddr should call transferOwnership() to THIS contract!!!
contract ProposalsContract {
	address public bridgeAddr;
	address public multisigAddress;
	PreserveBalancesOnTransferToken public token;

	uint public QUORUM_PERCENT = 80;
	uint public CONSENSUS_PERCENT = 80;

	event VotingStarted(string _type, uint _param, uint _totalSupplyAtEvent, uint _eventId, address _byWhom);
	event VotingFinished();

	enum VotingType {
		SetExitStake,
		SetEpochLength
	}

	struct Voting {
		VotingType votingType;
		uint param;
		uint eventId;
		uint pro;
		uint versus;
		uint totalSupplyAtEvent;
		address[] voted;
	}

	Voting[] votings;

	constructor(address _bridgeAddr, PreserveBalancesOnTransferToken _token, address _multisigAddress) public {
		multisigAddress = _multisigAddress;
		bridgeAddr = _bridgeAddr;
		token = _token;
	}

	function setExitStake(uint256 _exitStake) public {
		require(msg.sender==multisigAddress);
		uint eventId = token.startNewEvent();
		uint totalSupplyAtEvent = token.totalSupply();
		Voting v;
		v.votingType = VotingType.SetExitStake;
		v.param = _exitStake;
		v.eventId = eventId;
		v.pro = 0;
		v.versus = 0;
		v.totalSupplyAtEvent = totalSupplyAtEvent;
		votings.push(v);
	
		emit VotingStarted("setExitStake", _exitStake, totalSupplyAtEvent, eventId, msg.sender);
	}

	function setEpochLength(uint256 _epochLength) public {
		require(msg.sender==multisigAddress);
		uint eventId = token.startNewEvent();
		uint totalSupplyAtEvent = token.totalSupply();
		Voting v;
		v.votingType = VotingType.SetEpochLength;
		v.param = _epochLength;
		v.eventId = 0;
		v.pro = 0;
		v.versus = 0;
		v.totalSupplyAtEvent = totalSupplyAtEvent;
		votings.push(v);

		// vote(0, true);
		emit VotingStarted("setEpochLength", _epochLength, totalSupplyAtEvent, eventId, msg.sender);
	}

	function getVotingsCount()public view returns(uint){
		return votings.length;
	}

	function getVoting(uint _i) public view returns(VotingType votingType, uint paramValue, address startedBy) {
		votingType = votings[_i].votingType;
		paramValue = votings[_i].param;
		startedBy = votings[_i].startedBy;
	}

	function getVotingStats(uint _i) public view returns(uint pro, uint versus, bool isFinished, bool isResultYes) {
		pro = votings[_i].pro;
		versus = votings[_i].versus;
		isFinished = _isFinished(_i);
		isResultYes = _isResultYes(_i);
	}

	function _isFinished(uint _i) internal returns(bool isFin) {
		uint a = QUORUM_PERCENT * votings[_i].totalSupplyAtEvent;
		uint b = (votings[_i].pro + votings[_i].versus) * 100;
		isFin = (b >= a);
	}

	function _isResultYes(uint _i) internal view returns(bool isYes) {
		isYes = (votings[_i].versus <= ((100-CONSENSUS_PERCENT)*votings[_i].pro));
	}

	function _isVoted(uint _i, address _a) internal view returns(bool isVoted) {
		for(uint j=0; j<votings[_i].voted.length; j++) {
			if(votings[_i].voted[j]==_a) {
				isVoted = true;
			}
		}
	}	

	function vote(uint _i, bool _isYes) public {
		require(!_isFinished(_i));
		uint tokenHolderBalance = token.getBalanceAtEventStart(0, msg.sender);
		require(!_isVoted(_i, msg.sender));
		votings[_i].voted.push(msg.sender);
		// 1 - recalculate stats
		if(_isYes){
			votings[_i].pro += tokenHolderBalance;
		}else{
			votings[_i].versus += tokenHolderBalance;
		}
		
		// 2 - if voting is finished (last caller) AND the result is YES -> call the target method 
		if(_isFinished(_i) && _isResultYes(_i)){
			emit VotingFinished();
			if(votings[_i].votingType==VotingType.SetExitStake){
				BridgeTestable(bridgeAddr).setExitStake(votings[_i].param);
			}else if(votings[_i].votingType==VotingType.SetEpochLength) {
				BridgeTestable(bridgeAddr).setEpochLength(votings[_i].param);
				
			}
			token.finishEvent(votings[_i].eventId);
		}

	}
}
