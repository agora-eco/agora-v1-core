const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { MarketFactory } from "../../src/types/MarketFactory"
import { Market } from "../../src/types/Market";
import { Secondary } from "../../src/types/Secondary";

describe("SecondaryMarket", () => {
    let accounts: Signer[];
    let marketFactory: MarketFactory;
    let market: Market;
	let secondaryMarket: Secondary;
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
        
        it("Add Default Market Extension", async () => {
            const addDefaultMarketExtensionTx = await marketFactory
                .connect(alice)
                .addExtension("Default Market", market.address);
            await addDefaultMarketExtensionTx.wait();
        });

        it("Deploy Secondary Market", async () => {
            const SecondaryMarket = await ethers.getContractFactory("Secondary");
            secondaryMarket = await SecondaryMarket.deploy();
        });

        it("Add Secondary Market Extension", async () => {
            const addSecondaryMarketExtensionTx = await marketFactory
                .connect(alice)
                .addExtension("Secondary Market", secondaryMarket.address);
            await addSecondaryMarketExtensionTx.wait();
        });
    });

    describe("Create Product", async () => {
        it("Owner Create Product", async () => {
			const aliceCreateProductTxn = await secondaryMarket
				.connect(alice)
				["createProduct(string,string,uint256,uint256)"](
					"MS",
					"Milkshake",
					ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
					1
				);
			await aliceCreateProductTxn.wait();
		});
    });

    describe("Purchase Product", () => {
        it("Valid Product Purchase", async () => {
            const bobPurchaseTxn = await secondaryMarket.connect(bob).purchaseProduct(
                "item1", 1, {
				    value: ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
			    }
            );
            await bobPurchaseTxn.wait();
        });
    })
})