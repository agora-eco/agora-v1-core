// SPDX-License-Identifier: MIT
/** 
    Users can buy a stake in the market to own a portion of secondary sales.
*/

pragma solidity ^0.8.0;

import {Secondary} from "./Secondary.sol";
import {Treasury} from "./Treasury.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Stakable is Secondary, Treasury {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _shareHolderId;
    Counters.Counter private _shareListingId;

    uint256 totalShares;
    uint256 holderAllocation;

    mapping(uint256 => address) _indexableHolders;
    mapping(address => ShareHolder) _shareHolders;
    mapping(uint256 => ShareListing) _shareListings;

    struct ShareHolder {
        bool exists;
        uint256 count;
        uint256 forSale;
        uint256 earned;
        uint256 balance;
    }
    struct ShareListing {
        bool exists;
        bool active;
        bool settled;
        uint256 amount;
        uint256 pricePerShare;
        address owner;
    }

    event Reap(
        address indexed owner,
        uint256 shares,
        uint256 localizedEarnings
    );
    event ListShares(
        address indexed initiator,
        uint256 amount,
        uint256 pricePerShare
    );
    event PurchaseShares(
        address indexed lister,
        address indexed initiator,
        uint256 amount,
        uint256 pricePerShare
    );

    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _marketplaceFee,
        uint256 _totalShares,
        uint256 _holderAllocation
    ) Secondary(_symbol, _name, _marketplaceFee) {
        totalShares = _totalShares;
        holderAllocation = _holderAllocation; // % distributed to shareholders: comes out of marketplaceFee
        _shareHolderId.increment();
        _indexableHolders[_shareHolderId.current()] = msg.sender;
    }

    // allocate funds amongst holders: assign to treasury
    function allocate(address shareHolder, uint256 amount) private {
        require(_shareHolders[shareHolder].count >= 0, "invalid shareholder");
        _shareHolders[msg.sender].earned += amount;
        _shareHolders[msg.sender].balance += amount;
    }

    function calculateSplit(address shareHolder)
        private
        pure
        returns (uint256)
    {
        require(_shareHolders[shareHolder].count > 0, "invalid amount");
        uint256 marketCut = msg.value.mul(marketplaceFee.div(100)); // msg.value * (fee/100)
        return
            marketCut.mul(
                (_shareHolders[shareHolder].count.div(totalShares.mul(100)))
            ); // marketCut * ((owning / (totalpool * 100))
    }

    function withdraw() external {
        ShareHolder memory shareHolder = _shareHolders[msg.sender];
        require(shareHolder.balance >= 0, "invalid shareholder");
        payable(msg.sender).transfer(shareHolder.balance);

        emit Reap(msg.sender, shareHolder.count, shareHolder.balance);

        _shareHolders[msg.sender].balance = 0;
    }

    function distribute() private {
        // implement
        for (
            uint256 shareHolderId = 1;
            shareHolderId < _shareHolderId.current();
            shareHolderId++
        ) {
            allocate(
                _indexableHolders[shareHolderId],
                calculateSplit(_indexableHolders[shareHolderId])
            );
        }
    }

    function purchase(string memory productCode, uint256 quantity)
        external
        payable
        override
        productNotExist(productCode)
        isActive
    {
        Product memory product = _catalog[productCode];

        require(quantity > 0, "invalid quantity");
        require(product.quantity > 0, "product oos");
        require(product.quantity >= quantity, "insufficient stock");
        require(
            (product.price * 10**18).mul(quantity) <= msg.value,
            "insufficient funds"
        );

        product.quantity -= quantity;
        _catalog[productCode] = product;

        payable(owner).transfer(product.price);

        emit Purchase(
            productCode,
            product.name,
            quantity,
            product.price.mul(quantity),
            tx.origin
        );
    }

    function purchase(uint256 listingId) external payable override isActive {
        Listing memory listing = _listings[listingId];
        require(listing.exists == true, "listing dne");
        require(listing.owner != msg.sender, "owner");
        require(listing.active == true, "listing inactive");
        require(listing.settled == false, "listing settled");
        require(listing.price * 10**18 <= msg.value, "insufficient funds");

        uint256 marketCut = msg.value.mul(marketplaceFee.div(100)); // value * (marketplaceFee / 100)
        payable(listing.owner).transfer(msg.value - marketCut);
        payable(owner).transfer(marketCut);

        listing.active = false;
        listing.settled = true;
        _listings[listingId] = listing;

        emit Purchase(
            listing.productCode,
            listing.name,
            1,
            listing.price,
            tx.origin
        );
    }

    function listShares(uint256 amount, uint256 pricePerShare)
        external
        returns (uint256)
    {
        require(
            _shareHolders[msg.sender].count.sub(
                _shareHolders[msg.sender].forSale
            ) >= amount,
            "insufficient remaining shares"
        );

        _shareListingId.increment();
        uint256 newListingId = _shareListingId.current();

        _shareHolders[msg.sender].forSale.add(amount);
        _shareListings[newListingId] = ShareListing(
            true,
            true,
            false,
            amount,
            pricePerShare,
            msg.sender
        );
        emit ListShares(msg.sender, amount, pricePerShare);
        return newListingId;
    }

    function modifyListing(uint256 shareListingId, bool state) external {
        ShareListing memory listing = _shareListings[shareListingId];
        require(listing.exists == true, "share listing dne");
        require(listing.owner == msg.sender, "not owner");
        require(listing.settled == false, "share listing settled");

        listing.active = state;
        _shareListings[shareListingId] = listing;
    }

    function modifyListing(
        uint256 shareListingId,
        uint256 amount,
        uint256 pricePerShare
    ) external {
        ShareListing memory listing = _shareListings[shareListingId];
        require(listing.exists == true, "share listing dne");
        require(listing.owner == msg.sender, "not owner");
        require(listing.settled == false, "share listing settled");

        listing.amount = amount;
        listing.pricePerShare = pricePerShare;
        _shareListings[shareListingId] = listing;
    }

    function purchaseShares(uint256 shareListingId, uint256 amount)
        external
        payable
    {
        ShareListing memory listing = _shareListings[shareListingId];
        require(listing.exists == true, "share listing dne");
        require(listing.active == true, "share listing inactive");
        require(listing.settled == false, "share listing settled");
        require(listing.amount >= amount, "insufficient shares");
        require(
            msg.value >= listing.pricePerShare.mul(amount),
            "insufficient funds"
        );

        ShareHolder memory listerHoldings = _shareHolders[listing.owner];
        ShareHolder memory buyerHoldings = _shareHolders[msg.sender];

        listing.amount -= amount;
        if (listing.amount == 0) {
            listing.settled = true;
            listing.active = false;
        }
        _shareListings[shareListingId] = listing;

        listerHoldings.count -= amount;
        listerHoldings.forSale -= amount;
        _shareHolders[listing.owner] = listerHoldings;

        if (_shareHolders[msg.sender].exists == false) {
            _shareHolderId.increment();
            _indexableHolders[_shareHolderId.current()] = msg.sender;
        }

        _shareHolders[msg.sender] = ShareHolder(
            true,
            buyerHoldings.count + amount,
            buyerHoldings.forSale,
            buyerHoldings.earned,
            buyerHoldings.balance
        );

        payable(listing.owner).transfer(msg.value);

        emit PurchaseShares(
            listing.owner,
            msg.sender,
            amount,
            listing.pricePerShare
        );
    }

    function inspectHolder(address shareHolder)
        external
        view
        returns (ShareHolder memory)
    {
        return _shareHolders[shareHolder];
    }
}
