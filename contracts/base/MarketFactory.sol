// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "hardhat/console.sol";

import "./Market.sol";

contract MarketFactory {
    // create name registry to support extension contracts
    using Strings for string;

    address public paymentProxyAddress;
    address[] public markets;
    mapping(address => string) public marketRegistry;
    mapping(address => bool) internal _registered;
    mapping(address => bool) internal _verified;
    mapping(string => UpgradeableBeacon) internal _extensionRegistry;

    constructor(address _paymentProxyAddress) {
        paymentProxyAddress = _paymentProxyAddress;
    }

    function addExtension(string calldata extensionName, address logic)
        external
    {
        _extensionRegistry[extensionName] = new UpgradeableBeacon(logic);
    }

    function upgradeExtension(string calldata extensionName, address logic)
        external
    {
        _extensionRegistry[extensionName].upgradeTo(logic);
    }

    function deployMarket(string calldata extensionName, bytes calldata data)
        external
        returns (address)
    {
        BeaconProxy proxy = new BeaconProxy(
            address(_extensionRegistry[extensionName]),
            data
        );
        address proxyAddress = address(proxy);

        markets.push(proxyAddress);
        marketRegistry[proxyAddress] = extensionName;
        _registered[proxyAddress] = true;

        return proxyAddress;
    }

    function disableMarket(address _market) public {
        // update market to disable. irreversible
        // only market owner can disable
        //market.disable(true);
    }

    function verify(address _market, bool _state) public {
        // must be admin
        _verified[_market] = _state;
        // emit
    }
}
