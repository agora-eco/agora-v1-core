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
    mapping (address => mapping(string => uint256)) public _holdingsBook; // owner => product code => n_holdings

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
        __SecondaryMarket_init_unchained(_marketplaceFee);
    }

    function __SecondaryMarket_init_unchained(uint256 _marketplaceFee) 
    internal 
    initializer {
        marketplaceFee = _marketplaceFee;
    }

    /**
     * primary product purchase
     * @dev See {IMarket-purchase} 
     */
    function purchase(string calldata productCode, uint256 quantity)
        external
        payable
        virtual
        override
        productExist(productCode)
        isActive
    {
        Product memory product = _catalog[productCode];

        require(quantity > 0, "invalid quantity");
        require(product.quantity > 0, "product oos");
        require(product.quantity >= quantity, "insufficient stock");
        require(quantity * product.price <= msg.value, "insufficient funds");

        product.quantity -= quantity;
        _catalog[productCode] = product;

        uint256 marketCut = msg.value * marketplaceFee / 100; // value * (marketplaceFee / 100)
        payable(product.owner).transfer(product.price - marketCut);
        payable(owner).transfer(marketCut);

        _holdingsBook[msg.sender][productCode] += quantity;

        emit Purchase(
            productCode,
            product.name,
            quantity,
            product.price * quantity,
            _msgSender()
        );
    }

    /**
     * secondary create
     * @dev See {IMarket-create}
     */
    function create(
        string memory productCode,
        uint256 price,
        uint256 quantity
    ) 
    public
    virtual
    {
        require(_holdingsBook[msg.sender][productCode] >= quantity, "selling more than you own");
        Product memory product = _catalog[productCode];
        string memory productName = product.name;
        _catalog[productCode] = Product(
            true,
            price,
            productName,
            quantity,
            _msgSender(),
            false
        );
        _holdingsBook[msg.sender][productCode] -= quantity;

        emit Create(productCode, productName, price, quantity, _msgSender());
    }
}
