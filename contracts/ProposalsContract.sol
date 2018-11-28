pragma solidity ^0.4.24;

import "@thetta/core/contracts/tokens/PreserveBalancesOnTransferToken.sol";
import "@thetta/core/contracts/tokens/SnapshotToken.sol";

import "./BridgeTestable.sol";


/**
 * @title ProposalsContract 
 * @dev This is the implementation of Proposals contract.
 * See https://github.com/leapdao/leap-contracts/blob/master/contracts/LeapBridge.sol
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
		uint totalSupplyAtEvemapping(address=>bool);
		mapping(address=>bool) voted;
	}

	Voting[] votings;

	modifier onlyMultisigAddress() {
		require(msg.sender==multisigAddress);
		_;
	}

	/**
	 * @notice _bridgeAddr SHOULD CALL transferOwnership() to THIS contract!
	 * @param _bridgeAddr – address of the bridge contract (that we will control)
	 * @param _token – address of the main DAO token
	 * @param _multisigAddress – address of the mulitisig contract (that controls us)
	 */
	constructor(address _bridgeAddr, PreserveBalancesOnTransferToken _token, address _multisigAddress) public {
		multisigAddress = _multisigAddress;
		bridgeAddr = _bridgeAddr;
		token = _token;
	}

	/**
	 * @dev Propose the 'exitStake' parameter change
	 * @notice This function creates voting
	 * @param uint256 _exitStake – value of exitStake param
	 */
	function setExitStake(uint256 _exitStake) public onlyMultisigAddress {
		Voting v;
		v.votingType = VotingType.SetExitStake;
		v.param = _exitStake;
		v.eventId = token.startNewEvent();
		v.pro = 0;
		v.versus = 0;
		v.totalSupplyAtEvent = token.totalSupply();
		votings.push(v);
	
		emit VotingStarted("setExitStake", _exitStake, v.totalSupplyAtEvent, v.eventId, msg.sender);
	}

	/**
	 * @dev Propose the 'epochLength' parameter change
	 * @notice This function creates voting
	 * @param uint256 _epochLength – value of epochLength param
	 */
	function setEpochLength(uint256 _epochLength) public onlyMultisigAddress {
		Voting v;
		v.votingType = VotingType.SetEpochLength;
		v.param = _epochLength;
		v.eventId = token.startNewEvent();
		v.pro = 0;
		v.versus = 0;
		v.totalSupplyAtEvent = token.totalSupply();
		votings.push(v);
		
		emit VotingStarted("setEpochLength", _epochLength, v.totalSupplyAtEvent, v.eventId, msg.sender);
	}

	/**
	 * @dev Get ALL voting count 
	 * @notice This function can be called by anyone
	 * @return uint Voting count
	 */
	function getVotingsCount()public view returns(uint){
		return votings.length;
	}

	/**
	* @dev Get voting data
	 * @notice This function can be called by anyone
	 * @param uint _votingIndex – voting number
	 * @return VotingType votingType – what is this voting for
	 * @return uint paramValue – what is param amount
	 * @return uint versus – sum of voters token amount, that voted no
	 * @return bool isFinished – is Quorum reached
	 * @return bool isResultYes – is voted yes >= 80%
	 */
	function getVotingStats(uint _votingIndex) public view returns(VotingType votingType, uint paramValue, uint pro, uint versus, bool isFinished, bool isResultYes) {
		votingType = votings[_votingIndex].votingType;
		paramValue = votings[_votingIndex].param;		
		pro = votings[_votingIndex].pro;
		versus = votings[_votingIndex].versus;
		isFinished = _votingIndexsFinished(_votingIndex);
		isResultYes = _votingIndexsResultYes(_votingIndex);
	}

	/**
	* @dev Is selected voting finished?
	 * @param uint _votingIndex – voting number
	 * @return is quorum reched or not
	 */
	function _votingIndexsFinished(uint _votingIndex) internal returns(bool isFin) {
		uint a = QUORUM_PERCENT * votings[_votingIndex].totalSupplyAtEvent;
		uint b = (votings[_votingIndex].pro + votings[_votingIndex].versus) * 100;
		isFin = (b >= a);
	}

	/**
	 * @dev Is selected voting result is YES? 
	 * @notice Not checking whether it is finished!
	 * @param uint _votingIndex – voting number
	 * @return is current result yes or not
	 */
	function _votingIndexsResultYes(uint _votingIndex) internal view returns(bool isYes) {
		isYes = (votings[_votingIndex].versus <= ((100-CONSENSUS_PERCENT)*votings[_votingIndex].pro));
	}

	/**
	* @dev Has token holder already voted?
	 * @param uint _votingIndex – voting number
	 * @param address _a – potential voter address
	 * @return Has voted or not
	 */
	function _votingIndexsVoted(uint _votingIndex, address _a) internal view returns(bool isVoted) {
		isVoted = votings[_votingIndex].voted[_a];
	}	

	/**
	 * @dev Vote YES or NO
	 * @param uint _votingIndex – voting number
	 * @param bool _votingIndexsYes – voters opinion
	 */
	function vote(uint _votingIndex, bool _votingIndexsYes) public {
		require(!_votingIndexsFinished(_votingIndex));

		uint tokenHolderBalance = token.getBalanceAtEventStart(votings[_votingIndex].eventId, msg.sender);
		require(tokenHolderBalance);
		require(!_votingIndexsVoted(_votingIndex, msg.sender));

		votings[_votingIndex].voted[msg.sender] = true;

		// 1 - recalculate stats
		if(_votingIndexsYes){
			votings[_votingIndex].pro += tokenHolderBalance;
		}else{
			votings[_votingIndex].versus += tokenHolderBalance;
		}
		
		// 2 - if voting is finished (last caller) AND the result is YES -> call the target method 
		if(_votingIndexsFinished(_votingIndex) && _votingIndexsResultYes(_votingIndex)){
			emit VotingFinished();

			if(votings[_votingIndex].votingType==VotingType.SetExitStake){
				BridgeTestable(bridgeAddr).setExitStake(votings[_votingIndex].param);
			}else if(votings[_votingIndex].votingType==VotingType.SetEpochLength) {
				BridgeTestable(bridgeAddr).setEpochLength(votings[_votingIndex].param);		
			}

			token.finishEvent(votings[_votingIndex].eventId);
		}
	}
}
