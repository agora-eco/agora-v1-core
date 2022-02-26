const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { MarketFactory } from "../src/Types/MarketFactory";
import { Market } from "../src/Types/Market";
import { NFTLaunchMarket } from "../src/Types/NFTLaunchMarket";
import DefaultMarketAbi from "../artifacts/contracts/base/Market.sol/Market.json";
import NFTLaunchAbi from "../artifacts/contracts/examples/NFTMarket/NFTLaunchMarket.sol/NFTLaunchMarket.json";

describe("NFT Launch Market", () => {
	let accounts: Signer[];
	let marketFactory: MarketFactory;
	let market: Market;
	let nftLaunchMarket: NFTLaunchMarket;
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

		it("Deploy NFT Launch Market", async () => {
			const Market = await ethers.getContractFactory("NFTLaunchMarket");
			nftLaunchMarket = await Market.deploy();
		});

		it("Add Default Market Extension", async () => {
			const addFactoryExtensionTx = await marketFactory
				.connect(alice)
				.addExtension("Default", market.address);
			await addFactoryExtensionTx.wait();
		});

		it("Add NFT Launch Market Extension", async () => {
			const addFactoryExtensionTx = await marketFactory
				.connect(alice)
				.addExtension("NFT Launch", nftLaunchMarket.address);
			await addFactoryExtensionTx.wait();
		});
	});

	describe("Manage Market", () => {
		it("Deploy NFT Launch Market", async () => {
			const iface = new ethers.utils.Interface([
				"function initialize(string _symbol, string _name, uint256 _maxPerOwner)",
			]);
			const createMarketTxn = await marketFactory
				.connect(bob)
				.deployMarket(
					1,
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
			nftLaunchMarket = await ethers.getContractAt(
				"NFTLaunchMarket",
				newMarketAddress
			);

			expect(await nftLaunchMarket.owner()).to.equal(
				await bob.getAddress()
			);
		});
	});

	describe("Establish Catalog", () => {
		it("Create NFT Product", async () => {
			const createProductTxn = await nftLaunchMarket
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
			const agoraGenesisNft = await nftLaunchMarket.inspectItem("AGNFT");
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
		it("Mint Excess", async () => {
			const mintNftTxn = nftLaunchMarket
				.connect(alice)
				.purchase("AGNFT", 3, {
					value: ethers.BigNumber.from(
						(0.18 * 3 * 10 ** 18).toString()
					),
				});

			await expect(mintNftTxn).to.be.revertedWith("Exceeds maxPerOwner");
		});

		it("Mint", async () => {
			const mintNftTxn = await nftLaunchMarket
				.connect(alice)
				.purchase("AGNFT", 2, {
					value: ethers.BigNumber.from(
						(0.18 * 2 * 10 ** 18).toString()
					),
				});

			await mintNftTxn.wait();
		});

		it("Check Balance", async () => {
			const balanceOfAlice = await nftLaunchMarket.balanceOf(
				await alice.getAddress()
			);

			await expect(balanceOfAlice).to.equal(
				ethers.BigNumber.from((2).toString())
			);
		});

		it("Mint", async () => {
			const mintNftTxn = await nftLaunchMarket
				.connect(bob)
				.purchase("AGNFT", 1, {
					value: ethers.BigNumber.from((0.18 * 10 ** 18).toString()),
				});

			await mintNftTxn.wait();
		});

		it("Check Balance", async () => {
			const balanceOfBob = await nftLaunchMarket.balanceOf(
				await bob.getAddress()
			);

			await expect(balanceOfBob).to.equal(
				ethers.BigNumber.from((1).toString())
			);
		});

		it("Check Total Supply", async () => {
			const totalSupply = await nftLaunchMarket.totalSupply();
			await expect(totalSupply).to.equal(
				ethers.BigNumber.from((3).toString())
			);
		});
	});
});
