// SPDX-License-Identifier: MIT
/** 
    Users can relist products and market owner gets a fee.
*/

pragma solidity ^0.8.0;

import {Market} from "../base/Market.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Secondary is Market {
    uint256 public marketplaceFee;

    function initialize(
        string memory _symbol,
        string memory _name,
        uint256 _marketplaceFee
    ) 
    public 
    virtual 
    initializer {
        __SecondaryMarket_init(_symbol, _name, _marketplaceFee);
    }

    function __SecondaryMarket_init(
        string memory _symbol,
        string memory _name,
        uint256 _marketplaceFee
    ) 
    internal 
    initializer {
        __AccessControl_init_unchained();
        __Market_init_unchained(_symbol, _name);
        __SecondaryMarket_init_unchained(_symbol, _name, _marketplaceFee);
    }

    function __SecondaryMarket_init_unchained(
        string memory _symbol,
        string memory _name,
        uint256 _marketplaceFee
    ) 
    internal 
    initializer {
        marketplaceFee = _marketplaceFee;
    }
}
