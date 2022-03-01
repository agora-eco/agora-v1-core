const hre = require("hardhat");

const MARKET = "0x1C5AA0FEf163a5F7e24B6699E22A4e527Ca2df2e";

async function main() {
	const [deployer] = await ethers.getSigners();
	const market = await hre.ethers.getContractAt("Market", MARKET);

	const createProductTxn = await market.purchase("BGR", 1, {
		value: ethers.BigNumber.from((0.1 * 10 ** 18).toString()),
	});

	await createProductTxn.wait();
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
