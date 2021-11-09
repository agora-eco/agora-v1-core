// SPDX-License-Identifier: MIT
/** 
    Users can buy a stake in the market to own a portion of secondary sales.
*/

pragma solidity ^0.8.0;

import {Secondary} from "./Secondary.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Stakable is Secondary {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _shareIds;

    uint256 totalShares;
    uint256 holderAllocation;
    mapping(uint256 => ShareHolder) _shareHolders;

    struct ShareHolder {
        address owner;
        uint256 count;
        uint256 earned;
    }

    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _marketplaceFee,
        uint256 _totalShares,
        uint256 _holderAllocation
    ) Secondary(_symbol, _name, _marketplaceFee) {
        totalShares = _totalShares;
        holderAllocation = _holderAllocation;
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

    function inspectHolder(uint256 shareId)
        external
        view
        returns (ShareHolder memory)
    {
        return _shareHolders[shareId];
    }
}
