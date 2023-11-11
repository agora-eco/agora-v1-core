// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IMarket.sol";
import "./MarketFactory.sol";
import "./Market.sol";

// equal market = anyone can create product
contract ExtensionMarket is Initializable, Market {
    // extension owners list extension
    // handle deployment via marketfactory
    MarketFactory marketFactory;

    function initialize(
        string memory _symbol,
        string memory _name,
        MarketFactory _marketFactory
    ) public initializer {
        __ExtensionMarket_init(_symbol, _name, _marketFactory);
    }

    function __ExtensionMarket_init(
        string memory _symbol,
        string memory _name,
        MarketFactory _marketFactory
    ) internal initializer {
        __Market_init_unchained(_symbol, _name);
        __ExtensionMarket_init_unchained(_marketFactory);
    }

    function __ExtensionMarket_init_unchained(MarketFactory _marketFactory)
        internal
        initializer
    {
        marketFactory = _marketFactory;
    }

    // deploy market in extensionMarket. Extension Equal Market

    // extension owners only can create products for their respective extension
}
