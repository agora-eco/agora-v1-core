// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

// upgradeable
contract Merchant {
    using Counters for Counters.Counter;
    Counters.Counter private _productIds;

    string public name;
    string public symbol;
    string public imageBase;
    address payable public owner;

    struct product {
        string name;
        string code;
        string description;
        string imageHash;
        uint256 price;
        uint256 stock;
        bool active;
        bool hidden;
    }

    mapping(uint256 => product) products;

    modifier exists(uint256 serial) {
        require(
            serial <= _productIds.current(),
            "Merchant: product does not exist"
        );
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = payable(tx.origin);
    }

    function addProduct(
        string memory _name,
        string memory _code,
        string memory _description,
        string memory _imageHash,
        uint256 _price,
        uint256 _stock,
        bool _active,
        bool _hidden
    ) external {
        _productIds.increment();
        products[_productIds.current()] = product({
            name: _name,
            code: _code,
            description: _description,
            imageHash: _imageHash,
            price: _price * 10**18,
            stock: _stock,
            active: _active,
            hidden: _hidden
        });
    }

    function handleActiveState(uint256 serial, bool activeState)
        external
        exists(serial)
    {
        products[serial].active = activeState;
    }

    function handleHiddenState(uint256 serial, bool hiddenState)
        external
        exists(serial)
    {
        products[serial].active = hiddenState;
    }

    function getProduct(uint256 serial)
        public
        view
        exists(serial)
        returns (product memory)
    {
        return products[serial];
    }

    function purchase(uint256 serial) public payable exists(serial) {
        require(products[serial].active, "Merchant: product is not active");
        require(
            products[serial].hidden == false,
            "Merchant: product is hidden"
        );
        require(
            products[serial].stock > 0,
            "Merchant: product is out of stock"
        );
        require(msg.value == products[serial].price, "Merchant: invalid value");
    }

    function setPrice(uint256 serial, uint256 price) public exists(serial) {
        products[serial].price = price * 10**18;
    }
}
