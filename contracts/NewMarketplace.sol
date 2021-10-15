// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NewMarketplace {
    string private _name;
    string private _symbol;

    struct Product {
        bool exists;
        bool onSale;
        uint256 quantity;
        uint256 stock;
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
        require(
            _merchants[merchant].catalog[code].onSale,
            "product not on sale"
        );
        require(
            _merchants[merchant].catalog[code].stock == 0,
            "product out of stock"
        );
        require(
            msg.value >= _merchants[merchant].catalog[code].price,
            "insufficient balance in txn"
        );

        _merchants[merchant].catalog[code].stock -= 1;

        if (_merchants[merchant].catalog[code].stock == 0) {
            _merchants[merchant].catalog[code].onSale = false;
        }

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
        smite product
    */
    function yeet(string memory merchant, string memory code) external {
        _merchants[merchant].catalog[code].exists = false;
    }

    /*
        get product
    */
    function getProduct(string memory merchant, string memory code)
        view
        returns ()
    {}

    /*
        merchants register to be queued for approval
    */
    function register(
        string memory name,
        string memory merchant,
        string memory description
    ) external {
        require(_merchants[merchant].exists == false, "merchant exists");

        _merchants[merchant].exists = true;
        _merchants[merchant].name = name;
        _merchants[merchant].description = description;
        _merchants[merchant].owners[msg.sender] = true;
    }

    /*
        remove merchant (deactivate)
    */
    function remove(string memory merchant) external {
        require(_merchants[merchant].owners[msg.sender], "not owner");
        require(_merchants[merchant].exists, "merchant dne");

        _merchants[merchant].exists = false;
    }

    /*
        admins approve merchants to start selling on marketplace
    */
    function approve(string memory merchant) external {
        require(_merchants[merchant].exists, "merchant dne");
        require(true, "not admin"); // must be admin

        _merchants[merchant].approved = true;
    }
}
