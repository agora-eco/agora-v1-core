const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { MarketFactory } from "../src/Types/MarketFactory";
import { Market } from "../src/Types/Market";
import { Secondary } from "../src/Types/Secondary";

describe("Secondary", () => {
	let alice: Signer, bob: Signer;
	let secondary: Secondary;
	let marketFactory: MarketFactory;
	let market: Market;
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
		it("Deploy Default Market", async () => {
			const Market = await ethers.getContractFactory("Market");
			market = await Market.deploy();
		});
		it("Deploy Secondary Market", async () => {
			const Secondary = await ethers.getContractFactory("Secondary");
			secondary = await Secondary.deploy();
		});
		it("Add Default Market Extension", async () => {
			const addDefaultMarketExtensionTx = await marketFactory
				.connect(alice)
				.addExtension("Default Market", market.address);
			await addDefaultMarketExtensionTx.wait();
		});
		it("Add Secondary Market Extension", async () => {
			const addSecondaryMarketExtensionTx = await marketFactory
				.connect(alice)
				.addExtension("Secondary", secondary.address);
			await addSecondaryMarketExtensionTx.wait();
		});
	});

	describe("Manage Market", () => {
		it("Deploy", async () => {
			const iface = new ethers.utils.Interface([
				"function initialize(string _symbol, string _name, uint256 _marketplaceFee)",
			]);
			const createMarketTxn = await marketFactory
				.connect(alice)
				.deployMarket(
					"Secondary",
					iface.encodeFunctionData("initialize", [
						"TPM",
						"Test Proxied Market",
						1,
					])
				);

			await createMarketTxn.wait();
		});

		it("Retrieve", async () => {
			const newMarketAddress = await marketFactory.markets(0);
			secondary = await ethers.getContractAt(
				"Secondary",
				newMarketAddress
			);
			expect(await secondary.owner()).to.equal(await alice.getAddress());
		});
	});

	describe("Establish catalog", () => {
		it("owner create product", async () => {
			const aliceCreateProductTxn = await secondary
				.connect(alice)
				["create(string,string,uint256,uint256)"](
					"MS",
					"Milkshake",
					(1 * 10 ** 17).toString(),
					1
				);
			await aliceCreateProductTxn.wait();
		});

		it("disallow non-owner create product", async () => {
			const bobCreateProductTxn = secondary
				.connect(bob)
				["create(string,string,uint256,uint256)"](
					"BMS",
					"Bad Milkshake",
					(1 * 10 ** 17).toString(),
					1
				);
			await expect(bobCreateProductTxn).to.be.revertedWith(
				"must be admin"
			);
		});
	});
});
