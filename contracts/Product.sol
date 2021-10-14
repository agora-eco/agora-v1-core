// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IProduct.sol";

contract Product is IProduct {
    struct ProductStruct {
        string name;
        string description;
        uint256 price;
        uint256 supply;
    }
    mapping(uint256 => ProductStruct) private _products;
}
