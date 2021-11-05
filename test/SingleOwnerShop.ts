/*
[Alice, Bob] = [Wallet 1, Wallet 2]

Alice creates store ✔
Bob purchases product X

Alice creates product w/ stock 1 ✔
Bob creates product X

Bob purchases product ✔
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

describe("SingleOwnerShop", () => {
	let accounts;
	let SingleOwnerShop, singleOwnerShop;

	before(async () => {
		accounts = await ethers.getSigners();
		SingleOwnerShop = await ethers.getContractFactory("SingleOwnerShop");
		singleOwnerShop = await SingleOwnerShop.deploy("RBS", "Rich Boy Shop");
	});

	it("Store Creation", async () => {
		const [alice, bob] = accounts;
		const validCreateProductTxn = await singleOwnerShop
			.connect(alice)
			.create("MS", "Milkshake", 0.1, 1);
		await validCreateProductTxn.wait();

		try {
			const invalidCreateProductTxn = await singleOwnerShop
				.connect(bob)
				.create("BMS", "Bad Milkshake", 0.1, 1);
			await invalidCreateProductTxn.wait();
		} catch (error) {
			expect(error.message).to.equal(
				"VM Exception while processing transaction: reverted with reason string: 'not owner'"
			);
		}
	});

	it("Catalog Inspection", async () => {
		const [alice, bob] = accounts;

		expect(await singleOwnerShop.inspect("MS")).to.eql([
			true, // exists
			ethers.BigNumber.from(0.1), // price
			"Milkshake", // name
			1, // quantity
		]);

		try {
			await singleOwnerShop.inspect("BMS");
		} catch (error) {
			expect(error.message).to.equal(
				"VM Exception while processing transaction: reverted with reason string: 'product dne'"
			);
		}
	});

	it("Purchase", async () => {
		const [alice, bob] = accounts;

		try {
			const bobPurchaseTxn = await singleOwnerShop
				.connect(bob)
				.purchase("MS", 10, {
					value: (10 * 0.1 * 10 ** 18).toString(),
				});
			await bobPurchaseTxn.wait();
		} catch (error) {
			expect(error.message).to.equal(
				"VM Exception while processing transaction: reverted with reason string: 'insufficient stock'"
			);
		}

		try {
			const bobPurchaseTxn = await singleOwnerShop
				.connect(bob)
				.purchase("MS", 1, {
					value: 0,
				});
			await bobPurchaseTxn.wait();
		} catch (error) {
			expect(error.message).to.equal(
				"VM Exception while processing transaction: reverted with reason string: 'insufficient funds'"
			);
		}

		const bobPurchaseTxn = await singleOwnerShop
			.connect(bob)
			.purchase("MS", 1, {
				value: (0.1 * 10 ** 18).toString(),
			});
		await bobPurchaseTxn.wait();

		expect(await singleOwnerShop.inspect("MS")).to.eql([
			true, // exists
			ethers.BigNumber.from(0.1), // price
			"Milkshake", // name
			0, // quantity
		]);

		// check for funds decreasing

		try {
			const bobPurchaseTxn2 = await singleOwnerShop
				.connect(bob)
				.purchase("MS", 1, {
					value: 0,
				});
			await bobPurchaseTxn2.wait();
		} catch (error) {
			expect(error.message).to.equal(
				"VM Exception while processing transaction: reverted with reason string: 'product oos'"
			);
		}
	});

	it("Restock", async () => {
		try {
			const bobRestockTxn = await singleOwnerShop
				.connect(bob)
				.restock("MS", 10, true);
			await bobRestockTxn.wait();
		} catch (error) {
			expect(error.message).to.equal(
				"VM Exception while processing transaction: reverted with reason string: 'not owner'"
			);
		}

		const aliceRestockTxn = await singleOwnerShop.restock("MS", 5);
		await aliceRestockTxn.wait();

		expect(await singleOwnerShop.inspect("MS")).to.eql([
			true, // exists
			ethers.BigNumber.from(0.1), // price
			"Milkshake", // name
			5, // quantity
		]);
	});
});
