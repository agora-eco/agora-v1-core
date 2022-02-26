const hre = require("hardhat");

const MF_CONTRACT_ADDRESS = "0x74547ab87685b1C360648A916bCfcde1B3e7f666";

/*
|  marketFactory  │ '0x74547ab87685b1C360648A916bCfcde1B3e7f666' │
│  defaultMarket  │ '0x768Ed6E31Fb8D5f1B39daf637f1FCD0828c73796' │
│ nftLaunchMarket │ '0xe038a3fCaB33A19Dd962b90884A446c687fA19bC' │
│ tokenSaleMarket │ '0x03F859f621Db055977A2aCb3E3AD6948bd20374A' |
*/

// deployedMarket = 0x1C5AA0FEf163a5F7e24B6699E22A4e527Ca2df2e

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
		0,
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
