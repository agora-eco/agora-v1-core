// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseShop} from "./BaseShop.sol";

/**
    Fundamental shop with stripped functionality. Will serve as basis for future iterations of marketplace

 */

contract SingleOwnerShop is BaseShop {
    address public owner;

    modifier onlyOwner() {
        require(tx.origin == owner, "not owner");
        _;
    }

    constructor(string memory _symbol, string memory _name) {
        _establish(_symbol, _name);
        owner = tx.origin;
    }

    function create(
        string memory _productCode,
        string memory _name,
        uint256 _price,
        uint256 _quantity
    ) public productNotExist(_productCode) onlyOwner {
        _create(_productCode, _name, _price, _quantity);
    }

    function adjust(
        string memory _productCode,
        string memory _name,
        uint256 _price
    ) public onlyOwner {
        _adjust(_productCode, _name, _price);
    }

    function purchase(string memory _productCode, uint256 _quantity)
        public
        payable
        productNotExist(_productCode)
    {
        _purchase(_productCode, _quantity, owner);
    }

    function restock(string memory _productCode, uint256 _quantity)
        public
        onlyOwner
        productNotExist(_productCode)
    {
        _restock(_productCode, _quantity);
    }

    function restock(
        string memory _productCode,
        uint256 _quantity,
        bool _forced
    ) public onlyOwner productNotExist(_productCode) {
        _restock(_productCode, _quantity, _forced);
    }

    function inspect(string calldata _productCode)
        external
        view
        returns (Product memory)
    {
        _inspect(_productCode);
    }
}
