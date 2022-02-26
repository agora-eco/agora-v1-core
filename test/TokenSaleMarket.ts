const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { MarketFactory } from "../src/Types/MarketFactory";
import { Market } from "../src/Types/Market";
import { TokenSaleMarket } from "../src/Types/TokenSaleMarket";

describe("Token Sale Market", () => {
	let accounts: Signer[];
	let marketFactory: MarketFactory;
	let market: Market;
	let tokenSaleMarket: TokenSaleMarket;
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

		it("Deploy Token Sale Market", async () => {
			const Market = await ethers.getContractFactory("TokenSaleMarket");
			tokenSaleMarket = await Market.deploy();
		});

		it("Add Default Market Extension", async () => {
			const addFactoryExtensionTx = await marketFactory
				.connect(alice)
				.addExtension("Default", market.address);
			await addFactoryExtensionTx.wait();
		});

		it("Add Token Sale Market Extension", async () => {
			const addFactoryExtensionTx = await marketFactory
				.connect(alice)
				.addExtension("Token Sale", tokenSaleMarket.address);
			await addFactoryExtensionTx.wait();
		});
	});

	describe("Manage Market", () => {
		it("Deploy Token Sale Market", async () => {
			const iface = new ethers.utils.Interface([
				"function initialize(string _symbol, string _name, uint256 maxSupply_, uint256 maxPerOwner_)",
			]);
			const createMarketTxn = await marketFactory
				.connect(bob)
				.deployMarket(
					"Token Sale",
					iface.encodeFunctionData("initialize", [
						"ATM",
						"Agora Token Market",
						ethers.utils.parseEther((1e10).toString()),
						ethers.utils.parseEther((5e5).toString()),
					])
				);

			await createMarketTxn.wait();
		});

		it("Retrieve", async () => {
			const newMarketAddress = await marketFactory.markets(0);
			tokenSaleMarket = await ethers.getContractAt(
				"TokenSaleMarket",
				newMarketAddress
			);

			expect(await tokenSaleMarket.owner()).to.equal(
				await bob.getAddress()
			);
		});
	});

	describe("Establish Catalog", () => {
		it("Create Token Product", async () => {
			const createProductTxn = await tokenSaleMarket
				.connect(bob)
				["create(string,string,uint256,uint256,bool)"](
					"AGT100T",
					"Agora Genesis Token x100000",
					ethers.BigNumber.from((1e6).toString()),
					ethers.utils.parseEther((1e5).toString()),
					false
				);

			await createProductTxn.wait();
		});

		it("Inspect TokenSale Product", async () => {
			const agtHt = await tokenSaleMarket.inspectItem("AGT100T");
			await expect(agtHt).to.eql([
				true,
				ethers.BigNumber.from((1e6).toString()),
				"Agora Genesis Token x100000",
				ethers.utils.parseEther((1e5).toString()),
				await bob.getAddress(),
				false,
			]);
		});
	});

	describe("Mint Tokens", () => {
		it("Mint Excess", async () => {
			const mintTokenTxn = tokenSaleMarket
				.connect(alice)
				.purchase(
					"AGT100T",
					ethers.utils.parseEther((5e5 + 1).toString()),
					{
						value: ethers.BigNumber.from(
							((5e5 + 1) * 1e6).toString()
						),
					}
				);

			await expect(mintTokenTxn).to.be.revertedWith(
				"Exceeds maxPerOwner"
			);
		});

		it("Mint", async () => {
			const mintTokenTxn = await tokenSaleMarket
				.connect(alice)
				.purchase("AGT100T", ethers.BigNumber.from((1e5).toString()), {
					value: ethers.BigNumber.from((1e5 * 1e6).toString()),
				});

			await mintTokenTxn.wait();
		});

		it("Check Balance", async () => {
			const balanceOfAlice = await tokenSaleMarket.balanceOf(
				await alice.getAddress()
			);

			await expect(balanceOfAlice).to.equal(
				ethers.BigNumber.from((1e5).toString())
			);
		});

		it("Check Total Supply", async () => {
			const totalSupply = await tokenSaleMarket.totalSupply();
			await expect(totalSupply).to.equal(
				ethers.BigNumber.from((1e5).toString())
			);
		});
	});
});
