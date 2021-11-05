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

    event Create(
        string productCode,
        string name,
        uint256 price,
        uint256 quantity,
        address indexed initiator
    );

    event Adjust(
        string productCode,
        string name,
        uint256 price,
        address indexed initiator
    );

    event Purchase(
        string name,
        uint256 quantity,
        uint256 value,
        address indexed initiator
    );

    event Restock(
        string productCode,
        string name,
        uint256 quantity,
        bool forced,
        address indexed initiator
    );

    modifier productNotExist(string memory _productCode) {
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
    ) public productNotExist(_productCode) onlyOwner {
        _catalog[_productCode] = Product(true, _price, _name, _quantity);

        emit Create(_productCode, _name, _price, _quantity, msg.sender);
    }

    function adjust(
        string memory _productCode,
        string memory _name,
        uint256 _price
    ) public onlyOwner {
        require(_catalog[_productCode].exists == true, "product dne");
        _catalog[_productCode] = Product(
            true,
            _price,
            _name,
            _catalog[_productCode].quantity
        );

        emit Adjust(_productCode, _name, _price, msg.sender);
    }

    function purchase(string memory _productCode, uint256 _quantity)
        public
        payable
        productNotExist(_productCode)
    {
        Product memory _product = _catalog[_productCode];

        require(_quantity > 0, "invalid quantity");
        require(_product.quantity > 0, "product oos");
        require(_product.quantity >= _quantity, "insufficient stock");
        require(
            _quantity * _product.price * 10**18 <= msg.value,
            "insufficient funds"
        );

        _product.quantity -= _quantity;
        _catalog[_productCode] = _product;

        payable(owner).transfer(_product.price);

        emit Purchase(
            _product.name,
            _quantity,
            _product.price * _quantity,
            msg.sender
        );
    }

    function restock(string memory _productCode, uint256 _quantity)
        public
        onlyOwner
        productNotExist(_productCode)
    {
        Product memory _product = _catalog[_productCode];

        _product.quantity += _quantity;
        _catalog[_productCode] = _product;

        emit Restock(_productCode, _product.name, _quantity, false, msg.sender);
    }

    function restock(
        string memory _productCode,
        uint256 _quantity,
        bool _forced
    ) public onlyOwner productNotExist(_productCode) {
        Product memory _product = _catalog[_productCode];

        if (_forced == true) {
            _product.quantity = _quantity;
        } else {
            _product.quantity += _quantity;
        }
        _catalog[_productCode] = _product;

        emit Restock(
            _productCode,
            _product.name,
            _quantity,
            _forced,
            msg.sender
        );
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
