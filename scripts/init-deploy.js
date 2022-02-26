const hre = require("hardhat");

async function main() {
	const [deployer] = await ethers.getSigners();

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

	const TokenSaleMarket = await hre.ethers.getContractFactory(
		"TokenSaleMarket"
	);
	const tokenSaleMarket = await TokenSaleMarket.deploy();

	await marketFactory.deployed();
	await market.deployed();
	await nftLaunchMarket.deployed();
	await tokenSaleMarket.deployed();

	const addMarketTxn = await marketFactory.addExtension(
		"Default",
		market.address
	);
	const addNftLaunchTxn = await marketFactory.addExtension(
		"NFT Launch",
		nftLaunchMarket.address
	);
	const addTokenSaleTxn = await marketFactory.addExtension(
		"Token Sale",
		tokenSaleMarket.address
	);

	await addMarketTxn.wait();
	await addNftLaunchTxn.wait();
	await addTokenSaleTxn.wait();

	let output = {};
	output.marketFactory = marketFactory.address;
	output.defaultMarket = market.address;
	output.nftLaunchMarket = nftLaunchMarket.address;
	output.tokenSaleMarket = tokenSaleMarket.address;
	console.table(output);

	console.log(`MarketFactory deployed to:`, marketFactory.address);
	console.log(`Default Market Extension deployed to:`, market.address);
	console.log(
		`NFT Launch Market Extension deployed to:`,
		nftLaunchMarket.address
	);
	console.log(
		`Token Sale Market Extension deployed to:`,
		tokenSaleMarket.address
	);

	//console.log(`[${marketSymbol}] ${marketName} deployed to:`, market.address);
}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
