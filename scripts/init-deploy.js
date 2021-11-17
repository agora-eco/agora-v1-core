const hre = require("hardhat");

async function main() {
	const marketSymbol = "RAM";
	const marketName = "Rich Ape Market";

	const Market = await hre.ethers.getContractFactory("Market");
	const market = await Market.deploy(marketSymbol, marketName);

	await market.deployed();

	console.log(`[${marketSymbol}] ${marketName} deployed to:`, market.address);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
