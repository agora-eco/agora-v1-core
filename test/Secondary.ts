

const { expect } = require("chai");
const { ethers } = require("hardhat");
import { Signer } from "ethers";
import { Secondary } from "../src/Types/Secondary";

describe('Secondary', () => {
    let alice: Signer, bob: Signer;
    let secondary: Secondary;
    before(async() => {
		[alice, bob] = await ethers.getSigners();
	});

    describe('Deploy market', ()=>{
        it('deploy', async()=>{
            const Secondary = await ethers.getContractFactory("Secondary");
            secondary = await Secondary.deploy();
            const initializeTxn = await secondary.initialize(
				"RBM",
				"Rich Boy Market"
			);
			await initializeTxn.wait();
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