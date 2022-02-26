const hre = require("hardhat");

const MF_CONTRACT_ADDRESS = "0x869c25d72bd36a6dbf59b1e3345a039e08d37561";

async function main() {
	const [deployer] = await ethers.getSigners();
	const marketFactory = await hre.ethers.getContractAt(
		"MarketFactory",
		MF_CONTRACT_ADDRESS
	);

	const iface = new hre.ethers.utils.Interface([
		"function initialize(string _symbol, string _name)",
	]);

	const deployMarketTxn = await marketFactory.deployMarket(
		"Default",
		iface.encodeFunctionData("initialize", ["FAM", "First Agora Market"])
	);

	await deployMarketTxn.wait();

	const deployedMarketAddress = await marketFactory.markets(0);
	console.log("Deployed Market:", deployedMarketAddress);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
