const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { MarketFactory } from "../src/Types/MarketFactory";
import { Market } from "../src/Types/Market";
import { NFTSaleMarket } from "../src/Types/NFTSaleMarket";
import DefaultMarketAbi from "../artifacts/contracts/base/Market.sol/Market.json";
import NFTSaleAbi from "../artifacts/contracts/examples/NFTMarket/NFTSaleMarket.sol/NFTSaleMarket.json";

describe("MarketFactory", () => {
	let accounts: Signer[];
	let marketFactory: MarketFactory;
	let market: Market;
	let nftSaleMarket: NFTSaleMarket;
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
		it("Deploy Default Market", async () => {
			const Market = await ethers.getContractFactory("Market");
			market = await Market.deploy();
		});

		it("Deploy NFT Sale Market", async () => {
			const Market = await ethers.getContractFactory("NFTSaleMarket");
			nftSaleMarket = await Market.deploy();
		});

		it("Add Default Market Extension", async () => {
			const addFactoryExtensionTx = await marketFactory
				.connect(alice)
				.addExtension("Default", market.address);
			await addFactoryExtensionTx.wait();
		});

		it("Add NFT Sale Market Extension", async () => {
			const addFactoryExtensionTx = await marketFactory
				.connect(alice)
				.addExtension("NFT Sale", nftSaleMarket.address);
			await addFactoryExtensionTx.wait();
		});
	});

	describe("Manage Market", () => {
		it("Deploy NFT Sale Market", async () => {
			const iface = new ethers.utils.Interface([
				"function initialize(string _symbol, string _name, uint256 _maxPerOwner)",
			]);
			const createMarketTxn = await marketFactory
				.connect(bob)
				.deployMarket(
					"NFT Sale",
					iface.encodeFunctionData("initialize", [
						"GFM",
						"GweiFace Market",
						ethers.BigNumber.from((2).toString()),
					])
				);

			await createMarketTxn.wait();
		});

		it("Retrieve", async () => {
			const newMarketAddress = await marketFactory.markets(0);
			nftSaleMarket = await ethers.getContractAt(
				"NFTSaleMarket",
				newMarketAddress
			);

			expect(await nftSaleMarket.owner()).to.equal(
				await bob.getAddress()
			);
		});
	});

	describe("Establish Catalog", () => {
		it("Create NFT Product", async () => {
			const createProductTxn = await nftSaleMarket
				.connect(bob)
				["create(string,string,uint256,uint256,bool)"](
					"AGNFT",
					"Agora Genesis NFT",
					ethers.BigNumber.from((0.18 * 10 ** 18).toString()),
					8888,
					true
				);

			await createProductTxn.wait();
		});

		it("Inspect NFT Product", async () => {
			const agoraGenesisNft = await nftSaleMarket.inspectItem("AGNFT");
			await expect(agoraGenesisNft).to.eql([
				true,
				ethers.BigNumber.from((0.18 * 10 ** 18).toString()),
				"Agora Genesis NFT",
				ethers.BigNumber.from(8888),
				await bob.getAddress(),
				true,
			]);
		});
	});

	describe("Mint NFT", () => {
		it("Mint", async () => {
			const mintNftTxn = await nftSaleMarket
				.connect(alice)
				.purchase("AGNFT", 2, {
					value: ethers.BigNumber.from((0.36 * 10 ** 18).toString()),
				});

			await mintNftTxn.wait();
		});

		it("Check Balance", async () => {
			const balanceOfAlice = await nftSaleMarket.balanceOf(
				await alice.getAddress()
			);

			await expect(balanceOfAlice).to.equal(
				ethers.BigNumber.from((2).toString())
			);
		});

		it("Mint", async () => {
			const mintNftTxn = await nftSaleMarket
				.connect(bob)
				.purchase("AGNFT", 1, {
					value: ethers.BigNumber.from((0.18 * 10 ** 18).toString()),
				});

			await mintNftTxn.wait();
		});

		it("Check Balance", async () => {
			const balanceOfBob = await nftSaleMarket.balanceOf(
				await bob.getAddress()
			);

			await expect(balanceOfBob).to.equal(
				ethers.BigNumber.from((1).toString())
			);
		});

		it("Check Total Supply", async () => {
			const totalSupply = await nftSaleMarket.totalSupply();
			await expect(totalSupply).to.equal(
				ethers.BigNumber.from((3).toString())
			);
		});
	});

	/*
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
	}); */
});
