const hre = require("hardhat");

const DEFAULT_MARKET = "0x3bbfcd0237fe92c1aa2fca76b39869f516aa9849";

async function main() {
	const [deployer] = await ethers.getSigners();
	const market = await hre.ethers.getContractAt(
		"Market",
		deployedMarketAddress
	);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
