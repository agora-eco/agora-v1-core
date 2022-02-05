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
        public
        returns (address)
    {
        Market market = new Market(_symbol, _name);
        address _marketAddress = address(market);
        _registered[_marketAddress] = true;
        marketRegistry.push(_marketAddress);
        return _marketAddress;
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
