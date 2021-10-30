// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    Fundamental marketplace with stripped functionality. Will serve as basis for future iterations of marketplace

 */

contract StrippedMarketplace {
    address owner;
    string public name;
    string public symbol;
    struct Product {
        bool exists;
        uint256 price;
        string name;
        uint256 quantity;
    }
    mapping(string => Product) _catalog;

    event Purchase(
        string name,
        uint256 quantity,
        uint256 value,
        address indexed initiator
    );

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    function create(
        string memory _productCode,
        uint256 _price,
        string memory _name,
        uint256 _quantity
    ) public {
        require(msg.sender == owner, "only owner can create");
        require(
            _catalog[_productCode].exists == false,
            "product already exists"
        );

        _catalog[_productCode] = Product(true, _price, _name, _quantity);
    }

    function purchase(string memory _productCode) public payable {
        Product memory _product = _catalog[_productCode];
        require(_product.exists == true, "product dne");
        require(_product.quantity > 0, "product oos");
        require(_product.price * 10**18 <= msg.value, "insufficient funds");

        _catalog[_productCode].quantity -= 1;
        payable(owner).transfer(_product.price);
        emit Purchase(_product.name, 1, _product.price * 1, msg.sender);
    }

    function inspect(string calldata _productCode)
        external
        view
        returns (Product memory)
    {
        Product memory _product = _catalog[_productCode];
        require(_product.exists == true, "product dne");

        return _product;
    }
}
