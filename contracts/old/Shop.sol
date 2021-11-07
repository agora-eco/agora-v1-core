// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Shop {
    string public name;
    string public symbol;
    mapping(string => Product) internal _catalog;

    struct Product {
        bool exists;
        uint256 price;
        string name;
        uint256 quantity;
    }

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

    function _establish(string memory _symbol, string memory _name) internal {
        symbol = _symbol;
        name = _name;
    }

    function _create(
        string memory _productCode,
        string memory _name,
        uint256 _price,
        uint256 _quantity
    ) internal productNotExist(_productCode) {
        _catalog[_productCode] = Product(true, _price, _name, _quantity);

        emit Create(_productCode, _name, _price, _quantity, tx.origin);
    }

    function _adjust(
        string memory _productCode,
        string memory _name,
        uint256 _price
    ) internal {
        require(_catalog[_productCode].exists == true, "product dne");
        _catalog[_productCode] = Product(
            true,
            _price,
            _name,
            _catalog[_productCode].quantity
        );

        emit Adjust(_productCode, _name, _price, tx.origin);
    }

    function _purchase(
        string memory _productCode,
        uint256 _quantity,
        address _owner
    ) internal productNotExist(_productCode) {
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

        payable(_owner).transfer(_product.price);

        emit Purchase(
            _product.name,
            _quantity,
            _product.price * _quantity,
            tx.origin
        );
    }

    function _restock(string memory _productCode, uint256 _quantity)
        internal
        productNotExist(_productCode)
    {
        Product memory _product = _catalog[_productCode];

        _product.quantity += _quantity;
        _catalog[_productCode] = _product;

        emit Restock(_productCode, _product.name, _quantity, false, tx.origin);
    }

    function _restock(
        string memory _productCode,
        uint256 _quantity,
        bool _forced
    ) internal productNotExist(_productCode) {
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
            tx.origin
        );
    }

    function _inspect(string calldata _productCode)
        internal
        view
        returns (Product memory)
    {
        Product memory _product = _catalog[_productCode];

        require(_product.exists == true, "product dne");

        return _product;
    }
}
