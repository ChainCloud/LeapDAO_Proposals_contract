pragma solidity ^0.4.22;

import "./PreserveBalancesOnTransferToken.sol";
import "./SnapshotToken.sol";

contract ProosalsContract {
	IBridgeContract bridgeContract;
	PreserveBalancesOnTransferToken token;

	event VotingStarted(string _type, uint _param, address _byWhom);
	...

	// TODO:
	struct Voting {
		address startedBy;
		string votingType;
		uint param;
		SnapshotToken snapshot;

		uint yesCount;
		uint noCount;
		// ...
	};
	Voting[] votings;

	// See https://github.com/leapdao/leap-contracts/blob/master/contracts/LeapBridge.sol
	// _bridgeContract should call transferOwnership() to THIS contract!!!
	constructor(IBridgeContract _bridgeContract) public {
		bridgeContract = _bridgeContract;
	}

// Example:
	function setExitStake(uint256 _exitStake) public {
		// 1 - start new voting
		Voting v(...);
		votings.push(v);

		// 2 - start snapshot 
		v.snapshot = token.createNewSnapshot();

		VotingStarted("setExitStake",_exitStake,msg.sender);
	}

	function getVotingsCount()public view returns(uint){
		// TODO:
	}

	// TODO: add more vars in returns()?
	function getVoting(uint _index) public view 
		returns(string _paramName, uint _value, uint _dateStarted, address _startedBy)
	{
		// TODO:
	}

	// TODO: add more vars in returns()?
	function getVotingStats(uint _index) public view 
		returns(uint _yes, uint _no, bool _isFinished, bool _finishedWithResult)
	{
		// TODO:
	}

	function vote(uint _votingIndex, bool _isYes) public {
		Voting v = votings[_votingIndex];
		uint tokenHolderBalance = v.snapshotToken.balanceOf(msg.sender);

		bool isVotingFinished = ...;

		// 1 - recalculate stats
		if(!isVotingFinished){
			if(_isYes){
				v.yesCount+=tokenHolderBalance;
			}else{
				v.noCount+=tokenHolderBalance;
			}
		}

		bool isResultYes = ...;

		// 2 - if voting is finished (last caller) AND the result is YES -> call the target method 
		if(isVotingFinished && isResultYes){
			if(v.type=="setExitStake"){
				bridgeContract.setExitStake(v.param);

				// 2 - stopSnapshot
				Voting v = votings[_votingIndex];
				token.stopSnapshot(v.snapshotToken);
			}
		}
	}
}
