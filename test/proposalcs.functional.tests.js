var BridgeTest= artifacts.require("./BridgeTest");
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

	var bridgeTest;
	var proposalsContract;
	var preserveBalancesOnTransferToken;

	describe('Positive scenario I', function(){
		it('Should update params',async() => {
			preserveBalancesOnTransferToken = await PreserveBalancesOnTransferToken.new();
			bridgeTest = await BridgeTest.new();
			proposalsContract = await ProposalsContract.new(bridgeTest.address, preserveBalancesOnTransferToken.address);
		});
	});
});
