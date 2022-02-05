// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {IMarket} from "./interfaces/IMarket.sol";

/**
 * @dev Foundation of a market standard.
 */
contract Market is IMarket, AccessControl {
    // Admin role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Market owner. Original deployer of the market and super admin
    address public owner;

    // Market name
    string public name;

    // Market symbol
    string public symbol;

    // Market catalog URI used for offchain purposes. Where market metadata exists
    string public catalogUri;

    // Market paused
    bool public paused;

    // Mapping from string of product codes to Product struct
    mapping(string => Product) internal _catalog;

    /**
     * @dev Check if product does not exist in market catalog
     */
    modifier productNotExist(string memory productCode) {
        require(
            _catalog[productCode].exists == false,
            "product already exists"
        );
        _;
    }

    /**
     * @dev Check if product exists in market catalog
     */
    modifier productExist(string memory productCode) {
        require(_catalog[productCode].exists == true, "product dne");
        _;
    }

    /**
     * @dev Check if market is active
     */
    modifier isActive() {
        require(paused == false, "market is paused");
        _;
    }

    /**
     * @dev Check if txn origin is of admin role
     */
    modifier isAdmin() {
        require(hasRole(ADMIN_ROLE, _msgSender()), "must be admin");
        _;
    }

    /**
     * @dev Initalizes the market by setting a `symbol` and `name` to the market
     * Assigns owner to market and sets up roles
     */
    constructor(string memory _symbol, string memory _name) {
        symbol = _symbol;
        name = _name;
        owner = tx.origin;
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(ADMIN_ROLE, tx.origin);

        /* if (msg.sender != tx.origin) {
            _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        }*/

        emit Establish(_symbol, _name, tx.origin);
    }

    /**
     * @dev Assign and revoke role from `address` with action dependent on `state`
     */
    function manageRole(address _address, bool state) external {
        if (state) {
            grantRole(ADMIN_ROLE, _address);
        } else {
            revokeRole(ADMIN_ROLE, _address);
        }
    }

    /**
     * @dev See {IMarket-pause}
     */
    function pause(bool state) external override isAdmin {
        paused = state;

        emit Pause(state, _msgSender());
    }

    /**
     * @dev See {IMarket-create}
     */
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

        emit Create(productCode, productName, price, quantity, _msgSender());
    }

    /**
     * @dev See {IMarket-setCatalogUri}
     */
    function setCatalogUri(string memory _catalogUri)
        external
        override
        isAdmin
    {
        catalogUri = _catalogUri;
    }

    /**
     * @dev See {IMarket-adjust}
     */
    function adjust(
        string memory productCode,
        string memory productName,
        uint256 price
    ) external override isAdmin productExist(productCode) {
        _catalog[productCode] = Product( // change .price
            true,
            price,
            productName,
            _catalog[productCode].quantity,
            _msgSender()
        );

        emit Adjust(productCode, productName, price, _msgSender());
    }

    /**
     * @dev See {IMarket-purchase}
     */
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

    /**
     * @dev See {IMarket-restock}
     */
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

    /**
     * @dev See {IMarket-restock}
     */
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

    /**
     * @dev See {IMarket-inspectItem}
     */
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
