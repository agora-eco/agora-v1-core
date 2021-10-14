// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

import {UCoin} from "./UCoin.sol";

// safe math
// decouple merchant from marketplace

contract Marketplace is AccessControl {
    // structs
    struct Product {
        bool exists;
        string name;
        string symbol;
        string description;
        uint256 price;
    }

    struct Merchant {
        bool approved;
        bool exists;
        bool autoPay;
        mapping(address => bool) owners;
        mapping(string => Product) catalog;
        address payable recipient;
    }

    // roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // variables
    UCoin internal _ucoin;
    mapping(string => Merchant) internal _merchants;

    // modifiers
    modifier notExistMerchant(string memory _merchant) {
        require(
            !_merchants[_merchant].exists,
            "Marketplace: specified merchant already exists"
        );
        _;
    }

    modifier existMerchant(string memory _merchant) {
        require(
            _merchants[_merchant].exists,
            "Marketplace: specified merchant does not exist"
        );
        _;
    }

    modifier existProduct(string memory _merchant, string memory _symbol) {
        require(
            _merchants[_merchant].catalog[_symbol].exists,
            "Marketplace: specified product does not exist"
        );
        _;
    }

    modifier isMerchantOwner(string memory _merchant, address owner) {
        require(
            _merchants[_merchant].owners[owner],
            "Marketplace: is not owner of merchant"
        );
        _;
    }

    constructor(string memory name, string memory symbol) {
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    // functions
    function approve(string memory merchant) external {}

    function batchApprove(string[] memory merchants) external {}

    /*
     */
    function addMerchant(string memory merchant)
        external
        notExistMerchant(merchant)
    {
        _merchants[merchant].exists = true;
    }

    /*
     */
    function addMerchant(
        string memory merchant,
        bool autoPay,
        address payable recipient
    ) external notExistMerchant(merchant) {
        _merchants[merchant].exists = true;
        _merchants[merchant].autoPay = autoPay;
        _merchants[merchant].recipient = recipient;
    }

    /*
     */
    function setMerchantAutoPay(string memory merchant, bool autoPay)
        external
        existMerchant(merchant)
    {
        _merchants[merchant].autoPay = autoPay;
    }

    /*
     */
    function setMerchantAutoPay(
        string memory merchant,
        bool autoPay,
        address payable recipient
    ) external existMerchant(merchant) {
        _merchants[merchant].autoPay = autoPay;
        _merchants[merchant].recipient = recipient;
    }

    /*
     */
    function setMerchantRecipient(
        string memory merchant,
        address payable recipient
    ) external existMerchant(merchant) {
        _merchants[merchant].recipient = recipient;
    }

    /*
     */
    function removeMerchant(string memory merchant)
        external
        existMerchant(merchant)
    {
        _merchants[merchant].exists = false;
    }

    /*
     */
    function lookupMerchant(string memory merchant)
        public
        view
        existMerchant(merchant)
    {
        return;
    }

    /*
     */
    function addProduct(
        string memory merchant,
        string memory symbol,
        string memory name,
        uint256 price
    ) external existMerchant(merchant) existProduct(merchant, symbol) {
        _merchants[merchant].catalog[symbol].exists = true;
        _merchants[merchant].catalog[symbol].name = name;
        _merchants[merchant].catalog[symbol].price = price;
    }

    /*
     */

    /*
     */
    function purchase(string memory merchant, string memory symbol)
        external
        existMerchant(merchant)
        existProduct(merchant, symbol)
    {}

    // autopay merchant
    // make purchase
    // request refund
    // reject refund
    // refund purchase
    // change marketplace fee
    // manage owners and admins
    // handle marketplace metadata
    // withdraw treasury funds
}

// users must be part of a whitelist before being able to mint currency
// only approved addresses can whitelist
