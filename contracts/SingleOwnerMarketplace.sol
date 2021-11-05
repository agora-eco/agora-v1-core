// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    Fundamental marketplace with stripped functionality. Will serve as basis for future iterations of marketplace

 */

contract SingleOwnerMarketplace {
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

    event Restock(string name, uint256 quantity, address indexed initiator);

    modifier productExist(string memory _productCode) {
        require(
            _catalog[_productCode].exists == false,
            "product already exists"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(string memory _symbol, string memory _name) {
        symbol = _symbol;
        name = _name;
        owner = msg.sender;
    }

    function create(
        string memory _productCode,
        string memory _name,
        uint256 _price,
        uint256 _quantity
    ) public productExist(_productCode) onlyOwner {
        _catalog[_productCode] = Product(true, _price, _name, _quantity);
    }

    function purchase(string memory _productCode)
        public
        payable
        productExist(_productCode)
    {
        Product memory _product = _catalog[_productCode];

        require(_product.quantity > 0, "product oos");
        require(_product.price * 10**18 <= msg.value, "insufficient funds");

        _product.quantity -= 1;
        _catalog[_productCode] = _product;

        payable(owner).transfer(_product.price);
        emit Purchase(_product.name, 1, _product.price * 1, msg.sender);
    }

    function restock(string memory _productCode, uint256 quantity)
        public
        onlyOwner
        productExist(_productCode)
    {
        Product memory _product = _catalog[_productCode];

        _product.quantity += quantity;
        _catalog[_productCode] = _product;

        emit Restock(_product.name, quantity, msg.sender);
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
