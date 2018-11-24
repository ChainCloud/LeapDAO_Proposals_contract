var BridgeTest= artifacts.require("./BridgeTest");
var ProposalsContract = artifacts.require("./ProposalsContract");

require('chai')
	.use(require('chai-as-promised'))
	.use(require('chai-bignumber')(web3.BigNumber))
	.should();

contract('ProposalsContract', (accounts) => {
	const creator = accounts[0];

	var bridgeTest;
	var proposalsContract;

	describe('Positive scenario I', function(){
		it('Should update params',async() => {
			bridgeTest = await BridgeTest.new();
			proposalsContract = await ProposalsContract.new(bridgeTest.address, );
		});
	});
});
