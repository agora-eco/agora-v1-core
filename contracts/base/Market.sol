// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IMarket} from "./interfaces/IMarket.sol";

contract Market is IMarket, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    address public owner;
    string public name;
    string public symbol;
    string public catalogUri;
    bool public paused;
    mapping(string => Product) internal _catalog;

    // pause event

    modifier productNotExist(string memory productCode) {
        require(
            _catalog[productCode].exists == false,
            "product already exists"
        );
        _;
    }

    modifier productExist(string memory productCode) {
        require(_catalog[productCode].exists == true, "product dne");
        _;
    }

    modifier isActive() {
        require(paused == false, "market is paused");
        _;
    }

    modifier isAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "must be admin");
        _;
    }

    constructor(string memory _symbol, string memory _name) {
        symbol = _symbol;
        name = _name;
        owner = _msgSender();
        _setupRole(ADMIN_ROLE, _msgSender());

        /* if (msg.sender != tx.origin) {
            _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        }*/

        emit Establish(_symbol, _name, _msgSender());
    }

    function manageRole(address _address, bool state) external {
        if (state) {
            grantRole(ADMIN_ROLE, _address);
        } else {
            revokeRole(ADMIN_ROLE, _address);
        }
    }

    function pause(bool state) external override isAdmin {
        paused = state;
    }

    function create(
        string memory productCode,
        string memory productName,
        uint256 price,
        uint256 quantity
    ) external override isAdmin productNotExist(productCode) {
        _catalog[productCode] = Product(
            true,
            price,
            productName,
            quantity,
            _msgSender()
        );

        emit Create(productCode, name, price, quantity, _msgSender());
    }

    function setCatalogUri(string memory _catalogUri)
        external
        override
        isAdmin
    {
        catalogUri = _catalogUri;
    }

    function adjust(
        string memory productCode,
        string memory productName,
        uint256 price
    ) external override isAdmin productExist(productCode) {
        _catalog[productCode] = Product(
            true,
            price,
            productName,
            _catalog[productCode].quantity,
            _msgSender()
        );

        emit Adjust(productCode, name, price, _msgSender());
    }

    function purchase(string memory productCode, uint256 quantity)
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

        payable(owner).transfer(product.price);

        emit Purchase(
            productCode,
            product.name,
            quantity,
            product.price * quantity,
            _msgSender()
        );
    }

    function restock(string memory productCode, uint256 quantity)
        external
        override
        isAdmin
        productExist(productCode)
    {
        Product memory product = _catalog[productCode];

        product.quantity += quantity;
        _catalog[productCode] = product;

        emit Restock(productCode, product.name, quantity, false, _msgSender());
    }

    function restock(
        string memory productCode,
        uint256 quantity,
        bool forced
    ) external override isAdmin productExist(productCode) {
        Product memory product = _catalog[productCode];

        if (forced == true) {
            product.quantity = quantity;
        } else {
            product.quantity += quantity;
        }
        _catalog[productCode] = product;

        emit Restock(productCode, product.name, quantity, forced, _msgSender());
    }

    function inspectItem(string calldata productCode)
        external
        view
        override
        productExist(productCode)
        returns (Product memory)
    {
        Product memory product = _catalog[productCode];

        return product;
    }
}
