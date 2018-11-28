pragma solidity ^0.4.24;

import "@thetta/core/contracts/tokens/PreserveBalancesOnTransferToken.sol";
import "@thetta/core/contracts/tokens/SnapshotToken.sol";

import "./BridgeTestable.sol";


/**
 * @title ProposalsContract 
 * @dev This is the implementation of Proposals contract.
 * Used to control bridge by votings.
 * See https://github.com/leapdao/leap-contracts/blob/master/contracts/LeapBridge.sol
 * _bridgeAddr should call transferOwnership() to THIS contract
*/
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

	modifier onlyMultisigAddress() {
		require(msg.sender==multisigAddress);
		_;
	}

	constructor(address _bridgeAddr, PreserveBalancesOnTransferToken _token, address _multisigAddress) public {
		multisigAddress = _multisigAddress;
		bridgeAddr = _bridgeAddr;
		token = _token;
	}

	/**
	* @notice This function can be called by multisigAddress
	* @notice This function creates voting
	* @param uint256 _exitStake – value of param exitStake
	*/
	function setExitStake(uint256 _exitStake) public onlyMultisigAddress {
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

	/**
	* @notice This function can be called by multisigAddress
	* @notice This function creates voting
	* @param uint256 _epochLength – value of param epochLength
	*/
	function setEpochLength(uint256 _epochLength) public onlyMultisigAddress {
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
		
		emit VotingStarted("setEpochLength", _epochLength, totalSupplyAtEvent, eventId, msg.sender);
	}

	/**
	* @notice This function can be called by anyone
	* @return uint voting amount
	*/
	function getVotingsCount()public view returns(uint){
		return votings.length;
	}

	/**
	* @notice This function can be called by anyone
	* @param uint _i – voting number
	* @return VotingType votingType – what is this voting for
	* @return uint paramValue – what is param amount
	* @return uint versus – sum of voters token amount, that voted no
	* @return bool isFinished – is Quorum reached
	* @return bool isResultYes – is voted yes >= 80%
	*/
	function getVotingStats(uint _i) public view returns(VotingType votingType, uint paramValue, uint pro, uint versus, bool isFinished, bool isResultYes) {
		votingType = votings[_i].votingType;
		paramValue = votings[_i].param;		
		pro = votings[_i].pro;
		versus = votings[_i].versus;
		isFinished = _isFinished(_i);
		isResultYes = _isResultYes(_i);
	}

	/**
	* @notice This function is internal
	* @param uint _i – voting number
	* @return is quorum reched or not
	*/
	function _isFinished(uint _i) internal returns(bool isFin) {
		uint a = QUORUM_PERCENT * votings[_i].totalSupplyAtEvent;
		uint b = (votings[_i].pro + votings[_i].versus) * 100;
		isFin = (b >= a);
	}

	/**
	* @notice This function is internal
	* @param uint _i – voting number
	* @return is current result yes or not
	*/
	function _isResultYes(uint _i) internal view returns(bool isYes) {
		isYes = (votings[_i].versus <= ((100-CONSENSUS_PERCENT)*votings[_i].pro));
	}

	/**
	* @notice This function is internal
	* @param uint _i – voting number
	* @param address _a – potential voter address
	* @return is voted or not
	*/
	function _isVoted(uint _i, address _a) internal view returns(bool isVoted) {
		for(uint j=0; j<votings[_i].voted.length; j++) {
			if(votings[_i].voted[j]==_a) {
				isVoted = true;
			}
		}
	}	

	/**
	* @notice This function should be called only by tokenHolders
	* @param uint _i – voting number
	* @param bool _isYes – voters opinion
	* @dev this function add vote
	*/
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
