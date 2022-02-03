// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Required interface for underlying markets
 */
interface IMarket {
    /**
     * @dev Emitted when market of `symbol` at `name` is established by `owner`
     */
    event Establish(string symbol, string name, address indexed owner);

    /**
     * @dev Emitted when `productName` at `productCode` is created by `initiator`
     */
    event Create(
        string productCode,
        string productName,
        uint256 price,
        uint256 quantity,
        address indexed initiator
    );

    /**
     * @dev Emitted when `productName` at `productCode` is adjusted by `initiator`
     */
    event Adjust(
        string productCode,
        string productName,
        uint256 price,
        address indexed initiator
    );

    /**
     * @dev Emitted when `productName` at `productCode` is purchased by `initiator` at `value`
     */
    event Purchase(
        string productCode,
        string productName,
        uint256 quantity,
        uint256 value,
        address indexed initiator
    );

    /**
     * @dev Emitted when `productCode` is restocked by `initiator`
     */
    event Restock(
        string productCode,
        string name,
        uint256 quantity,
        bool forced,
        address indexed initiator
    );

    /**
     * @dev Emitted when `paused` state is manipulated by `initiator`
     */
    event Pause(bool paused, address indexed initiator);

    struct Product {
        bool exists;
        uint256 price;
        string name;
        uint256 quantity;
        address owner;
    }

    //function establish(string memory symbol, string memory name) external;

    /**
     * @dev Pauses all purchase activity from occuring in market
     *
     * Requirements:
     *
     * - origin of transaction must be ADMIN role.
     *
     * Emits a {Pause} event
     */
    function pause(bool state) external;

    /**
     * @dev Creates product of `productCode` in product catalog.
     *
     * Requirements:
     *
     * - origin of transaction must be ADMIN role.
     * - `productCode` must not already exist in market catalog.
     *
     * Emits a {Create} event
     */
    function create(
        string memory productCode,
        string memory name,
        uint256 price,
        uint256 quantity
    ) external;

    /**
     * @dev Changes catalogURI (to be used in case of migrating catalog off chain).
     *
     * Requirements:
     *
     * - origin of transaction must be ADMIN role.
     *
     */
    function setCatalogUri(string memory catalogUri) external;

    /**
     * @dev Adjust price of `productCode`
     *
     * Requirements:
     *
     * - origin of transaction must be ADMIN role.
     * - product of `productCode` must exist in market catalog.
     *
     * Emits an {Adjust} event
     */
    function adjust(
        string memory productCode,
        string memory name,
        uint256 price
    ) external;

    /**
     * @dev Subtract `quantity` of `productCode` from catalog
     *
     * Requirements:
     *
     * - product of `productCode` must exist in market catalog.
     * - market must not be paused
     * - incoming `quantity` must be greater than 0
     * - remaining `productCode` quantity must be greater than 0
     * - remaining `productCode` quantity must be greater than incoming `quantity`
     * - msg value must be greater than `quantity` * price of `productCode`
     *
     * Emits a {Purchase} event
     */
    function purchase(string memory productCode, uint256 quantity)
        external
        payable;

    /**
     * @dev Increments quantity of `productCode` by `quantity`
     *
     * Requirements:
     *
     * - origin of transaction must be ADMIN role.
     * - product of `productCode` must exist in market catalog.
     *
     * Emits a {Restock} event
     */
    function restock(string memory productCode, uint256 quantity) external;

    /**
     * @dev Forces quantity of `productCode` to `quantity`
     *
     * Requirements:
     *
     * - origin of transaction must be ADMIN role.
     * - product of `productCode` must exist in market catalog.
     *
     * Emits a {Restock} event
     */
    function restock(
        string memory productCode,
        uint256 quantity,
        bool forced
    ) external;

    /**
     * @dev Returns product of `productCode`
     *
     * Requirements:
     *
     * - product of `productCode` must exist in market catalog.
     */
    function inspectItem(string calldata productCode)
        external
        view
        returns (Product memory);
}
