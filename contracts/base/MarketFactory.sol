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
    // extension registry -> extension struct -> mapping(uint256 => ExtensionRegister)
    // market registry -> market struct -> mapping(address => MarketRegister)
    using Strings for string;

    address public paymentProxyAddress;
    address[] public markets;
    mapping(address => string) public marketRegistry;
    mapping(address => bool) internal _registered;
    mapping(address => bool) internal _verified;
    mapping(string => UpgradeableBeacon) internal _extensionRegistry;

    struct ExtensionRegister {
        bool exists;
        string name;
        UpgradeableBeacon proxy;
    }

    struct MarketRegister {
        bool exists;
        address location;
        address owner;
        uint256 extensionId;
    }

    event AddExtension(
        string extensionName,
        address indexed logic,
        address indexed deployer
    );
    event UpgradeExtension(
        string extensionName,
        address indexed oldLogic,
        address indexed logic
    );
    event DeployMarket(
        address indexed deployer,
        string extensionName,
        address indexed logic,
        bytes data,
        address indexed proxy
    );

    constructor(address _paymentProxyAddress) {
        paymentProxyAddress = _paymentProxyAddress;
    }

    function addExtension(string calldata extensionName, address logic)
        external
    {
        _extensionRegistry[extensionName] = new UpgradeableBeacon(logic);
        emit AddExtension(extensionName, logic, msg.sender);
    }

    function upgradeExtension(string calldata extensionName, address logic)
        external
    {
        address oldLogic = address(_extensionRegistry[extensionName]);
        _extensionRegistry[extensionName].upgradeTo(logic);
        emit UpgradeExtension(extensionName, oldLogic, logic);
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

        emit DeployMarket(
            msg.sender,
            extensionName,
            address(_extensionRegistry[extensionName]),
            data,
            proxyAddress
        );
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
