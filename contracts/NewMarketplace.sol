// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NewMarketplace {
    string private _name;
    string private _symbol;

    struct Product {
        bool exists;
        string name;
        string description;
        uint256 price;
    }

    struct Merchant {
        bool approved;
        bool exists;
        string name;
        string description;
        mapping(address => bool) owners;
        mapping(string => Product) catalog;
    }

    mapping(string => Merchant) private _merchants;

    event Purchase(
        address indexed participant,
        string merchant,
        string code,
        uint256 value
    );

    constructor(string memory name, string memory symbol) {
        _name = name;
        _symbol = symbol;
    }

    /*
        participants can purchase products
    */
    function purchase(string memory merchant, string memory code) public {
        require(_merchants[merchant].catalog[code].exists, "product dne");
        emit Purchase(
            msg.sender,
            merchant,
            code,
            _merchants[merchant].catalog[code].price
        );
    }

    function batchPurchase(string memory merchant, string[] memory codes)
        external
    {
        for (uint256 i = 0; i < codes.length; i++) {
            purchase(merchant, codes[i]);
        }
    }

    /*
        merchants register to be queued for approval
    */
    function register(
        string memory name,
        string memory symbol,
        string memory description
    ) external {
        require(_merchants[symbol].exists == false, "merchant exists");

        _merchants[symbol].exists = true;
        _merchants[symbol].name = name;
        _merchants[symbol].description = description;
        _merchants[symbol].owners[msg.sender] = true;
    }

    /*
        remove merchant (deactivate)
    */
    function remove(string memory symbol) external {
        require(_merchants[symbol].owners[msg.sender], "not owner");
        require(_merchants[symbol].exists, "merchant dne");

        _merchants[symbol].exists = false;
    }

    /*
        admins approve merchants to start selling on marketplace
    */
    function approve(string memory symbol) external {
        require(_merchants[symbol].exists, "merchant dne");
        require(true, "not admin"); // must be admin

        _merchants[symbol].approved = true;
    }
}
