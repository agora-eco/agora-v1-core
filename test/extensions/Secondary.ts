const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { MarketFactory } from "../../src/types/MarketFactory";
import { Secondary } from "../../src/types/Secondary";

describe("SecondaryMarket", () => {
    let accounts: Signer[];
    let marketFactory: MarketFactory;
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
        it("Deploy Secondary Market", async () => {
            const SecondaryMarket = await ethers.getContractFactory("Secondary");
            secondaryMarket = await SecondaryMarket.deploy();
        });

        it("Add Secondary Market Extension", async () => {
            const addSecondaryMarketExtensionTx = await marketFactory
                .connect(alice)
                .addExtension("Secondary", secondaryMarket.address);
            await addSecondaryMarketExtensionTx.wait();
        });
    });

    describe("Manage Market", () => {
		it("Deploy Secondary Market", async () => {
			const iface = new ethers.utils.Interface([
				"function initialize(string _symbol, string _name, uint256 _marketplaceFee)",
			]);
			const createSecondaryMarket = await marketFactory
				.connect(alice)
				.deployMarket(
					0,
					iface.encodeFunctionData("initialize", [
						"SEC",
						"Secondary Market",
						ethers.BigNumber.from((2).toString()),
					])
				);

			await createSecondaryMarket.wait();
		});

        it("Retrieve Secondary", async () => {
			const newMarketAddress = await marketFactory.markets(0);
			secondaryMarket = await ethers.getContractAt(
				"Secondary",
				newMarketAddress
			);

			expect(await secondaryMarket.owner()).to.equal(
				await alice.getAddress()
			);
		});
	});

    describe("Establish Primary Market Catalog", async () => {
        it("Owner Create Product In Primary Market Catalog", async () => {
			const aliceCreateProductTxn = await secondaryMarket
				.connect(alice)
				["create(string,string,uint256,uint256)"](
					"MS",
					"Milkshake",
					ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
					1
				);
			await aliceCreateProductTxn.wait();
		});

        it("Inspect Valid Product", async () => {
            const milkshake = await secondaryMarket.connect(alice).inspectItem("MS");
            
            await expect(milkshake).to.eql([
				true,
				ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
				"Milkshake",
				ethers.BigNumber.from(1),
				await alice.getAddress(),
				false,
			]);
        });
    });

    describe("Establish HoldingsBook", async () => {
        it("Valid Purchase From Primary Market should add to Secondary Market HoldingsBook", async () => {
            const alicePurchaseProductTxn = await secondaryMarket.connect(alice).purchaseProduct(
                "MS",
                1,
                {
                    value: ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
                }
            );

            await alicePurchaseProductTxn.wait();

            const secondaryMarketMilkshakeCount = await secondaryMarket.connect(alice).inspectHoldingCount(await alice.getAddress(), "MS");
            await expect(secondaryMarketMilkshakeCount).to.eql(ethers.BigNumber.from(1));

            const primaryMarketMilkshake = await secondaryMarket.connect(alice).inspectItem("MS");
            await expect(primaryMarketMilkshake).to.eql([
				true,
				ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
				"Milkshake",
				ethers.BigNumber.from(0),
				await alice.getAddress(),
				false,
			]);
        });
    });

    describe("Manage Listing", () => {
        it("Create Valid Listing should Add to Listing Mapping", async () => {
            const aliceCreateListingTxn = await secondaryMarket.connect(alice).createListing(
                "MS",
                ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
                1
            );
            await aliceCreateListingTxn.wait();

            const milkshakeListing = await secondaryMarket.connect(alice).inspectListing(1);
            await expect(milkshakeListing).to.eql([
                true,
                true,
                false,
                "MS",
                "Milkshake",
                ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
                await alice.getAddress()
            ]);
        });

        it("Valid purchasing a Listing should Update the Listing Mapping", async () => {
            const bobPurchaseListingTxn = await secondaryMarket.connect(bob).purchaseListing(
                1,
                1,
                {
                    value: ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
                }
            );
            await bobPurchaseListingTxn.wait();

            const milkshakeListing = await secondaryMarket.connect(alice).inspectListing(1);
            await expect(milkshakeListing).to.eql([
                true,
                false,
                true,
                "MS",
                "Milkshake",
                ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
                await alice.getAddress()
            ]);
        });
    });
})