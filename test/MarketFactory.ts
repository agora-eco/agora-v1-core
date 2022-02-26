const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { MarketFactory } from "../src/Types/MarketFactory";
import { Market } from "../src/Types/Market";
import DefaultMarketAbi from "../artifacts/contracts/base/Market.sol/Market.json";

describe("MarketFactory", () => {
	let accounts: Signer[];
	let marketFactory: MarketFactory;
	let market: Market;
	let market2: Market;
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

	describe("Initialize Proxies", () => {
		it("Deploy Default", async () => {
			const Market = await ethers.getContractFactory("Market");
			market = await Market.deploy();
		});

		it("Add Factory Extension", async () => {
			const addFactoryExtensionTx = await marketFactory
				.connect(alice)
				.addExtension("Default", market.address);
			await addFactoryExtensionTx.wait();
		});
	});

	describe("Manage Market", () => {
		it("Deploy", async () => {
			const iface = new ethers.utils.Interface([
				"function initialize(string _symbol, string _name)",
			]);
			const createMarketTxn = await marketFactory
				.connect(alice)
				.deployMarket(
					0,
					iface.encodeFunctionData("initialize", [
						"TPM",
						"Test Proxied Market",
					])
				);

			await createMarketTxn.wait();
		});

		it("Deploy 2nd", async () => {
			const iface = new ethers.utils.Interface([
				"function initialize(string _symbol, string _name)",
			]);
			const createMarketTxn = await marketFactory
				.connect(bob)
				.deployMarket(
					0,
					iface.encodeFunctionData("initialize", [
						"BM",
						"Bob's Beacon'd Market",
					])
				);

			await createMarketTxn.wait();
		});

		it("Retrieve", async () => {
			const newMarketAddress = await marketFactory.markets(0);
			market = await ethers.getContractAt("Market", newMarketAddress);
			expect(await market.owner()).to.equal(await alice.getAddress());
		});

		it("Retrieve 2nd", async () => {
			const newMarketAddress = await marketFactory.markets(1);
			market2 = await ethers.getContractAt("Market", newMarketAddress);

			expect(await market2.owner()).to.equal(await bob.getAddress());
		});
	});

	describe("Multirole", () => {
		it("Grant", async () => {
			const bobAddress = await bob.getAddress();
			const aliceGrantBobTxn = await market
				.connect(alice)
				.manageRole(bobAddress, true);
			await aliceGrantBobTxn.wait();

			const adminRole = await market.ADMIN_ROLE();
			const bobIsAdmin = await market.hasRole(adminRole, bobAddress);
			expect(bobIsAdmin).to.equal(true);
		});

		it("Remove", async () => {
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

	describe("Establish Catalog", () => {
		it("Owner Create Product", async () => {
			const aliceCreateProductTxn = await market
				.connect(alice)
				["create(string,string,uint256,uint256)"](
					"MS",
					"Milkshake",
					ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
					1
				);
			await aliceCreateProductTxn.wait();
		});

		it("Disallow Non-owner Create Product", async () => {
			const bobCreateProductTxn = market
				.connect(bob)
				["create(string,string,uint256,uint256)"](
					"BMS",
					"Bad Milkshake",
					(0.1 * 10 ** 18).toString(),
					1
				);
			await expect(bobCreateProductTxn).to.be.revertedWith(
				"must be admin"
			);
		});
	});

	describe("Inspect Catalog", () => {
		it("Valid Item Lookup", async () => {
			const milkshake = await market.inspectItem("MS");
			await expect(milkshake).to.eql([
				true, // exists
				ethers.BigNumber.from((0.1 * 10 ** 18).toString()), // price
				"Milkshake", // name
				ethers.BigNumber.from(1), // quantity
				await alice.getAddress(), // owner
				false, // locked
			]);
		});

		it("Invalid Item Lookup", async () => {
			await expect(market.inspectItem("BMS")).to.be.revertedWith(
				"product dne"
			);
		});
	});

	describe("Purchase Item", () => {
		it("Invalidate Excess Stock Purchase", async () => {
			const bobPurchaseTxn = market.connect(bob).purchase("MS", 10, {
				value: ethers.BigNumber.from((10 * 0.1 * 10 ** 18).toString()),
			});
			await expect(bobPurchaseTxn).to.be.revertedWith(
				"insufficient stock"
			);
		});

		it("Invalidate Insufficient Value Purchase", async () => {
			const bobPurchaseTxn = market.connect(bob).purchase("MS", 1, {
				value: 0,
			});
			await expect(bobPurchaseTxn).to.be.revertedWith(
				"insufficient funds"
			);
		});

		it("Valid Item Purchase", async () => {
			const bobPurchaseTxn = await market.connect(bob).purchase("MS", 1, {
				value: ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
			});
			await bobPurchaseTxn.wait();

			const milkshake = await market.inspectItem("MS");
			await expect(milkshake).to.eql([
				true,
				ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
				"Milkshake",
				ethers.BigNumber.from(0),
				await alice.getAddress(),
				false,
			]);
		});

		// decreasing funds

		it("Invalidate Out Of Stock Item Purchase", async () => {
			const bobPurchaseTxn = market.connect(bob).purchase("MS", 1, {
				value: 0,
			});
			await expect(bobPurchaseTxn).to.be.revertedWith("product oos");
		});
	});

	describe("Restock", () => {
		it("Disallow Non-owner Restock", async () => {
			const bobRestockTxn = market
				.connect(bob)
				["restock(string,uint256,bool)"]("MS", 10, true);
			await expect(bobRestockTxn).to.be.revertedWith("must be admin");
		});

		it("Owner Restock", async () => {
			const aliceRestockTxn = await market["restock(string,uint256)"](
				"MS",
				5
			);
			await aliceRestockTxn.wait();

			const milkshake = await market.inspectItem("MS");
			expect(milkshake).to.eql([
				true,
				ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
				"Milkshake",
				ethers.BigNumber.from(5),
				await alice.getAddress(),
				false,
			]);
		});
	});
});
