// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Market.sol";

contract MarketFactory {
    // create name registry to support extension contracts
    using Strings for string;

    address public paymentProxyAddress;
    address[] public marketRegistry;
    mapping(address => bool) internal _registered;
    mapping(address => bool) internal _verified;

    constructor(address _paymentProxyAddress) {
        paymentProxyAddress = _paymentProxyAddress;
    }

    function deployMarket(string memory _symbol, string memory _name)
        returns (address)
    {
        address _market = new Market(_symbol, _name);
        _registered[_market] = true;
        marketRegistry.push(_market);
        return _market;
    }

    function disableMarket(address _market) {
        // update market to disable. irreversible
        Market market = _market;
        // only market owner can disable
        //market.disable(true);
    }

    function verify(address _market, bool _state) {
        // must be admin
        _verified[_market] = _state;
        // emit
    }
}
