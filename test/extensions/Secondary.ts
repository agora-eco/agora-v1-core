const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { MarketFactory } from "../../src/Types/MarketFactory";
import { Market } from "../../src/Types/Market";
import { Secondary } from "../../src/Types/Secondary";

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
})