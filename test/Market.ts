/*
[alice, bob]: Signer[] = [Wallet 1, Wallet 2]

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
import { Signer } from "ethers";
import { Market } from "../src/Types/Market";

describe("Market", () => {
	let accounts: Signer[];
	let market: Market;
	let alice: Signer, bob: Signer;

	beforeEach(async () => {
		[alice, bob] = await ethers.getSigners();
	});

	describe("Deploy market", () => {
		it("deploy", async () => {
			const Market = await ethers.getContractFactory("Market");
			market = await Market.deploy("RBM", "Rich Boy Market");
		});
	});

	describe("Establish catalog", () => {
		it("owner create product", async () => {
			const validCreateProductTxn = await market
				.connect(alice)
				.create("MS", "Milkshake", (1 * 10 ** 17).toString(), 1);
			await validCreateProductTxn.wait();
		});

		it("non-owner create product", async () => {
			await expect(
				market
					.connect(bob)
					.create(
						"BMS",
						"Bad Milkshake",
						(1 * 10 ** 17).toString(),
						1
					)
			).to.be.revertedWith("must be admin");
		});
	});

	describe("Inspect catalog", () => {
		it("valid item lookup", async () => {
			await expect(market.inspectItem("MS")).to.eql([
				true, // exists
				(1 * 10 ** 17).toString(), // price
				"Milkshake", // name
				1, // quantity
				alice, // owner
			]);
		});

		it("invalid item lookup", async () => {
			await expect(market.inspectItem("BMS")).to.be.revertedWith(
				"product dne"
			);
		});
	});

	/*
	describe("Purchase item", () => {
		//purchase excess stock
		it('purchase excess stock', async () => {
			await expect(
				market.connect(bob).purchase("MS", 10, {
					value: (10 * 0.1 * 10 ** 18).toString(),
				})
			).to.be.revertedWith("insufficient stock");
		})

		it('purchase w/ insufficient value', async () => {
			await expect(
				market.connect(bob).purchase("MS", 1, {
					value: 0,
				})
			).to.be.revertedWith("insufficient funds");
		})

		it('valid item purchase', async () => {
			const bobPurchaseTxn = await market.connect(bob).purchase("MS", 1, {
				value: (0.1 * 10 ** 18).toString(),
			});
			await bobPurchaseTxn.wait();
		});

		it('decrease stock', async () => {
		await expect(market.inspectItem("MS")).to.eql([
				true, // exists
				(1 * 10 ** 17).toString(), // price
				"Milkshake", // name
				0, // quantity
				alice, // owner
			]);
		});
	});

		// check for funds decreasing

		it('purchase out of stock item', async () => {
			const bobPurchaseTxn = market.connect(bob).purchase("MS", 1, {
					value: 0,
				})
			await expect(
				await bobPurchaseTxn.wait()
			).to.be.revertedWith("product oos");
		});
	})
	})

	it("Restock", async () => {
		const [alice, bob]: Signer[] = accounts;

		//non-owner restock"
		await expect(
			market.connect(bob)["restock(string,uint256,bool)"]("MS", 10, true)
		).to.be.revertedWith("must be admin");

		//owner restock"
		const aliceRestockTxn = await market["restock(string,uint256)"](
			"MS",
			5
		);
		await aliceRestockTxn.wait();

		//item stock increase"
		market.inspectItem("MS").then((item) => {
			expect(item).to.eql([
				true, // exists
				(1 * 10 ** 17).toString(), // price
				"Milkshake", // name
				5, // quantity
				alice, // owner
			]);
		});
	});*/
});
