var BridgeTestable= artifacts.require("./BridgeTestable");
var ProposalsContract = artifacts.require("./ProposalsContract");
var PreserveBalancesOnTransferToken = artifacts.require("./PreserveBalancesOnTransferToken");

// let tx = await taskTable.addNewTask("Test", "Task for tests", true, false, neededWei, 1, 1);
// let events = tx.logs.filter(l => l.event === 'TaskTableElementAdded');
// let id = events[0].args._eId;

require('chai')
	.use(require('chai-as-promised'))
	.use(require('chai-bignumber')(web3.BigNumber))
	.should();

contract('ProposalsContract', (accounts) => {
	const creator = accounts[0];
	const u1 = accounts[1];
	const u2 = accounts[2];
	const u3 = accounts[3];
	const u4 = accounts[4];
	const u5 = accounts[5];

	var bridgeTestable;
	var proposalsContract;
	var preserveBalancesOnTransferToken;

	describe('Positive scenario I', function(){
		it('Should update params',async() => {
			preserveBalancesOnTransferToken = await PreserveBalancesOnTransferToken.new();

			await preserveBalancesOnTransferToken.mint(u1, 1e18);
			await preserveBalancesOnTransferToken.mint(u2, 1e18);
			await preserveBalancesOnTransferToken.mint(u3, 1e18);
			await preserveBalancesOnTransferToken.mint(u4, 1e18);
			await preserveBalancesOnTransferToken.mint(u5, 1e18);


			bridgeTestable = await BridgeTestable.new();
			proposalsContract = await ProposalsContract.new(bridgeTestable.address, preserveBalancesOnTransferToken.address);

			await preserveBalancesOnTransferToken.transferOwnership(proposalsContract.address);
			// await bridgeTestable.transferOwnership(proposalsContract.address);


			await proposalsContract.setEpochLength(500, {from:u1});
			// var EL1 = await bridgeTestable.epochLength();
			// assert.equal(EL1.toNumber(), 0);
			// await proposalsContract.vote(0, true, {from:u2});
			// await proposalsContract.vote(0, true, {from:u3});
			// await proposalsContract.vote(0, true, {from:u4});
			// await proposalsContract.vote(0, true, {from:u5});//.should.be.rejectedWith('revert');
			// var EL2 = await bridgeTestable.epochLength();
			// assert.equal(EL2.toNumber(), 500);
		});
	});
});