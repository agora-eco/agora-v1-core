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

    describe("Manage Market", () => {
		it("Deploy Secondary Market", async () => {
			const iface = new ethers.utils.Interface([
				"function initialize(string _symbol, string _name, uint256 _maxPerOwner)",
			]);
			const createSecondaryMarket = await marketFactory
				.connect(bob)
				.deployMarket(
					"Secondary Market",
					iface.encodeFunctionData("initialize", [
						"GFM",
						"GweiFace Market",
						ethers.BigNumber.from((2).toString()),
					])
				);

			await createSecondaryMarket.wait();
		});

        it("Retrieve", async () => {
			const newMarketAddress = await marketFactory.markets(0);
			secondaryMarket = await ethers.getContractAt(
				"Secondary",
				newMarketAddress
			);

			expect(await secondaryMarket.owner()).to.equal(
				await bob.getAddress()
			);
		});
	});

    describe("Establish Holdingsbook", async () => {
        it("Owner Create Product", async () => {
			const bobCreateProductTxn = await secondaryMarket
				.connect(bob)
				["create(string,string,uint256,uint256)"](
					"MS",
					"Milkshake",
					ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
					1
				);
			await bobCreateProductTxn.wait();
            
            const milkshake = await secondaryMarket.inspectProduct("MS");
            await expect(milkshake).to.eql([
				true,
				ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
				"Milkshake",
				ethers.BigNumber.from(1),
				await bob.getAddress(),
				false,
			]);
		});
    });

    // describe("Inspect Holdingsbook", async () => {
    //     it("Inspect Valid Product", async () => {
    //         const milkshake = await secondaryMarket.inspectProduct("MS");
            
    //         await expect(milkshake).to.eql([
	// 			true,
	// 			ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
	// 			"Milkshake",
	// 			ethers.BigNumber.from(1),
	// 			await bob.getAddress(),
	// 			false,
	// 		]);
    //     });
    // });

    // describe("Purchase Product", () => {
    //     it("Valid Product Purchase", async () => {
    //         const alicePurchaseTxn = await secondaryMarket.connect(alice).purchaseProduct(
    //             "MS", 1, {
	// 			    value: ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
	// 		    }
    //         );
    //         await alicePurchaseTxn.wait();
    //     });
    // });
})