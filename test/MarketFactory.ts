const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { MarketFactory } from "../src/Types/MarketFactory";
import { Market } from "../src/Types/Market";

describe("MarketFactory", () => {
	let accounts: Signer[];
	let marketFactory: MarketFactory;
	let market: Market;
	let alice: Signer, bob: Signer;

	before(async () => {
		[alice, bob] = await ethers.getSigners();
	});

	describe("Deploy MarketFactory", () => {
		it("deploy", async () => {
			const MarketFactory = await ethers.getContractFactory(
				"MarketFactory"
			);
			marketFactory = await MarketFactory.deploy(
				await alice.getAddress()
			);
		});
	});

	describe("Manage Market", () => {
		it("Deploy", async () => {
			const createMarketTxn = await marketFactory
				.connect(alice)
				.deployMarket("TFM", "TestFactoryMarket");
			await createMarketTxn.wait();
		});

		it("Retrieve", async () => {
			market = await ethers.getContractAt(
				"Market",
				await marketFactory.marketRegistry(0)
			);

			expect(await market.owner()).to.equal(await alice.getAddress());
		});
	});

	describe("Multirole", () => {
		it("grant", async () => {
			const bobAddress = await bob.getAddress();
			const aliceGrantBobTxn = await market
				.connect(alice)
				.manageRole(bobAddress, true);
			await aliceGrantBobTxn.wait();

			const adminRole = await market.ADMIN_ROLE();
			const bobIsAdmin = await market.hasRole(adminRole, bobAddress);
			expect(bobIsAdmin).to.equal(true);
		});

		it("reove", async () => {
			const bobAddress = await bob.getAddress();
			const aliceGrantBobTxn = await market
				.connect(alice)
				.manageRole(bobAddress, false);
			await aliceGrantBobTxn.wait();

			const adminRole = await market.ADMIN_ROLE();
			const bobIsAdmin = await market.hasRole(adminRole, bobAddress);
			expect(bobIsAdmin).to.equal(false);
		});
	});

	describe("Establish catalog", () => {
		it("owner create product", async () => {
			const aliceCreateProductTxn = await market
				.connect(alice)
				.create("MS", "Milkshake", (1 * 10 ** 17).toString(), 1);
			await aliceCreateProductTxn.wait();
		});

		it("disallow non-owner create product", async () => {
			const bobCreateProductTxn = market
				.connect(bob)
				.create("BMS", "Bad Milkshake", (1 * 10 ** 17).toString(), 1);
			await expect(bobCreateProductTxn).to.be.revertedWith(
				"must be admin"
			);
		});
	});

	describe("Inspect catalog", () => {
		it("valid item lookup", async () => {
			const milkshake = await market.inspectItem("MS");
			await expect(milkshake).to.eql([
				true, // exists
				ethers.BigNumber.from((1 * 10 ** 17).toString()), // price
				"Milkshake", // name
				ethers.BigNumber.from(1), // quantity
				await alice.getAddress(), // owner
			]);
		});

		it("invalid item lookup", async () => {
			await expect(market.inspectItem("BMS")).to.be.revertedWith(
				"product dne"
			);
		});
	});

	describe("Purchase item", () => {
		it("invalidate excess stock purchase", async () => {
			const bobPurchaseTxn = market.connect(bob).purchase("MS", 10, {
				value: (10 * 0.1 * 10 ** 18).toString(),
			});
			await expect(bobPurchaseTxn).to.be.revertedWith(
				"insufficient stock"
			);
		});

		it("invalidate insufficient value purchase", async () => {
			const bobPurchaseTxn = market.connect(bob).purchase("MS", 1, {
				value: 0,
			});
			await expect(bobPurchaseTxn).to.be.revertedWith(
				"insufficient funds"
			);
		});

		it("valid item purchase", async () => {
			const bobPurchaseTxn = await market.connect(bob).purchase("MS", 1, {
				value: (0.1 * 10 ** 18).toString(),
			});
			await bobPurchaseTxn.wait();

			const milkshake = await market.inspectItem("MS");
			await expect(milkshake).to.eql([
				true,
				ethers.BigNumber.from((1 * 10 ** 17).toString()),
				"Milkshake",
				ethers.BigNumber.from(0),
				await alice.getAddress(),
			]);
		});

		// decreasing funds

		it("invalidate out of stock item purchase", async () => {
			const bobPurchaseTxn = market.connect(bob).purchase("MS", 1, {
				value: 0,
			});
			await expect(bobPurchaseTxn).to.be.revertedWith("product oos");
		});
	});

	describe("Restock", () => {
		it("disallow non-owner restock", async () => {
			const bobRestockTxn = market
				.connect(bob)
				["restock(string,uint256,bool)"]("MS", 10, true);
			await expect(bobRestockTxn).to.be.revertedWith("must be admin");
		});

		it("owner restock", async () => {
			const aliceRestockTxn = await market["restock(string,uint256)"](
				"MS",
				5
			);
			await aliceRestockTxn.wait();

			const milkshake = await market.inspectItem("MS");
			expect(milkshake).to.eql([
				true,
				ethers.BigNumber.from((1 * 10 ** 17).toString()),
				"Milkshake",
				ethers.BigNumber.from(5),
				await alice.getAddress(),
			]);
		});
	});
});
