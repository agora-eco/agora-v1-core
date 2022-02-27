const hre = require("hardhat");

const MARKET = "0x1C5AA0FEf163a5F7e24B6699E22A4e527Ca2df2e";

async function main() {
	const [deployer] = await ethers.getSigners();
	const market = await hre.ethers.getContractAt("Market", MARKET);

	const createProductTxn = await market[
		"create(string,string,uint256,uint256)"
	]("BGR", "Burger", ethers.BigNumber.from((0.1 * 10 ** 18).toString()), 5);

	await createProductTxn.wait();
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
