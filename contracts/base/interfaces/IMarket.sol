// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarket {
    struct Product {
        bool exists;
        uint256 price;
        string name;
        uint256 quantity;
    }

    event Establish(string symbol, string name, address indexed owner);

    event Create(
        string productCode,
        string productName,
        uint256 price,
        uint256 quantity,
        address indexed initiator
    );

    event Adjust(
        string productCode,
        string productName,
        uint256 price,
        address indexed initiator
    );

    event Purchase(
        string productCode,
        string productName,
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

    function establish(string memory symbol, string memory name) external;

    function pause(bool state) external;

    function create(
        string memory productCode,
        string memory name,
        uint256 price,
        uint256 quantity
    ) external;

    function adjust(
        string memory productCode,
        string memory name,
        uint256 price
    ) external;

    function purchase(string memory productCode, uint256 quantity)
        external
        payable;

    function restock(string memory productCode, uint256 quantity) external;

    function restock(
        string memory productCode,
        uint256 quantity,
        bool forced
    ) external;

    function inspect(string calldata productCode)
        external
        view
        returns (Product memory);
}
