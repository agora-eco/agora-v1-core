// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IShop} from "./interfaces/IShop.sol";

contract Shop is IShop {
    string public name;
    string public symbol;
    bool public paused;
    mapping(string => Product) internal _catalog;

    modifier productNotExist(string memory productCode) {
        require(
            _catalog[productCode].exists == false,
            "product already exists"
        );
        _;
    }

    modifier isActive() {
        require(paused == false, "market is paused");
        _;
    }

    function establish(string memory _symbol, string memory _name)
        external
        override
    {
        symbol = _symbol;
        name = _name;

        emit Establish(_symbol, _name, tx.origin);
    }

    function pause(bool state) external override {
        paused = state;
    }

    function create(
        string memory productCode,
        string memory productName,
        uint256 price,
        uint256 quantity
    ) external override productNotExist(productCode) {
        _catalog[productCode] = Product(true, price, productName, quantity);

        emit Create(productCode, name, price, quantity, tx.origin);
    }

    function adjust(
        string memory productCode,
        string memory productName,
        uint256 price
    ) external override {
        require(_catalog[productCode].exists == true, "product dne");
        _catalog[productCode] = Product(
            true,
            price,
            productName,
            _catalog[productCode].quantity
        );

        emit Adjust(productCode, name, price, tx.origin);
    }

    function purchase(
        string memory productCode,
        uint256 quantity,
        address owner
    ) external payable override productNotExist(productCode) isActive {
        Product memory product = _catalog[productCode];

        require(quantity > 0, "invalid quantity");
        require(product.quantity > 0, "product oos");
        require(product.quantity >= quantity, "insufficient stock");
        require(
            quantity * product.price * 10**18 <= msg.value,
            "insufficient funds"
        );

        product.quantity -= quantity;
        _catalog[productCode] = product;

        payable(owner).transfer(product.price);

        emit Purchase(
            productCode,
            product.name,
            quantity,
            product.price * quantity,
            tx.origin
        );
    }

    function restock(string memory productCode, uint256 quantity)
        external
        override
        productNotExist(productCode)
    {
        Product memory product = _catalog[productCode];

        product.quantity += quantity;
        _catalog[productCode] = product;

        emit Restock(productCode, product.name, quantity, false, tx.origin);
    }

    function restock(
        string memory productCode,
        uint256 quantity,
        bool forced
    ) external override productNotExist(productCode) {
        Product memory product = _catalog[productCode];

        if (forced == true) {
            product.quantity = quantity;
        } else {
            product.quantity += quantity;
        }
        _catalog[productCode] = product;

        emit Restock(productCode, product.name, quantity, forced, tx.origin);
    }

    function inspect(string calldata productCode)
        external
        view
        override
        returns (Product memory)
    {
        Product memory product = _catalog[productCode];

        require(product.exists == true, "product dne");

        return product;
    }
}
