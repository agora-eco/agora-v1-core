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

    /* struct MarketParams {
        string symbol;
        string name;
    } */

    /*
    struct MarketEntry {
        string extensionName;
        address location;
    } */

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
        //MarketParams memory params = MarketParams(symbol, name);
        BeaconProxy proxy = new BeaconProxy(
            address(_extensionRegistry[extensionName]),
            /* abi.encodeWithSelector(
                Market(address(0)).initialize.selector,
                "SMB",
                "Symbol"
            ) */
            data
            //abi.encodeWithSignature("constructor(string,string)", symbol, name)
        );

        markets.push(address(proxy));
        marketRegistry[address(proxy)] = extensionName;

        return address(proxy);
        /* Market market = new Market(_symbol, _name);
        address _marketAddress = address(market);
        _registered[_marketAddress] = true;
        marketRegistry[_marketAddress] = _extension;
        return _marketAddress; */
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
