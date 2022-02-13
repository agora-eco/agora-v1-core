const hre = require("hardhat");

async function main() {
	const [deployer] = await ethers.getSigners();
	const marketSymbol = "RAM";
	const marketName = "Rich Ape Market";

	const MarketFactory = await hre.ethers.getContractFactory("MarketFactory");
	const marketFactory = await MarketFactory.deploy(
		await deployer.getAddress()
	);

	const Market = await hre.ethers.getContractFactory("Market");
	const market = await Market.deploy();

	const NFTLaunchMarket = await hre.ethers.getContractFactory(
		"NFTLaunchMarket"
	);
	const nftLaunchMarket = await NFTLaunchMarket.deploy();

	await marketFactory.deployed();
	await market.deployed();
	await nftLaunchMarket.deployed();

	const addMarketTxn = await marketFactory.addExtension(
		"Default",
		market.address
	);
	const addNftLaunchTxn = await marketFactory.addExtension(
		"NFT Launch",
		nftLaunchMarket.address
	);

	await addMarketTxn.wait();
	await addNftLaunchTxn.wait();

	let output = {};
	output.marketFactory = marketFactory.address;
	output.defaultMarket = market.address;
	output.nftLaunchMarket = nftLaunchMarket.address;
	console.table(output);

	console.log(`MarketFactory deployed to:`, marketFactory.address);
	console.log(`Default Market Extension deployed to:`, market.address);
	console.log(
		`NFT Launch Market Extension deployed to:`,
		nftLaunchMarket.address
	);

	//console.log(`[${marketSymbol}] ${marketName} deployed to:`, market.address);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
