/*
[Alice, Bob] = [Wallet 1, Wallet 2]

Alice creates store ✔
Bob purchases product X

Alice creates product w/ stock 1 ✔
Bob creates product ✔

Bob purchases product X
Alice funds rise ✔
Bobs funds decrease ✔
Stock drops 1 ✔

Product stock = 0 ✔
bob purchases product X
Bob restocks X
Alice restocks ✔
Product stock reflects ✔

Bob purchases product ✔

*/

const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StrippedMarketplace", () => {
	let accounts;
	let StrippedMarketplace, strippedMarketplace;

	before(async () => {
		accounts = await ethers.getSigners();
		StrippedMarketplace = ethers.getContractFactory("StrippedMarketplace");
		strippedMarketplace = await StrippedMarketplace.deploy(
			"RBM",
			"Rich Boy Marketplace"
		);
	});

	it("Store Creation", async () => {
		const [alice, bob] = accounts;
		const validCreateProductTxn = await strippedMarketplace
			.connect(alice)
			.create("MS", "Milkshake", 0.1, 4);
		await validCreateProductTxn.wait();

		try {
			const invalidCreateProductTxn = await strippedMarketplace
				.connect(bob)
				.create("BMS", "Bad Milkshake", 0.1, 1);
			await invalidCreateProductTxn.wait();
		} catch (err) {
			expect(err.message).to.equal(
				"VM Exception while processing transaction: reverted with reason string: 'not owner'"
			);
		}
	});
});
