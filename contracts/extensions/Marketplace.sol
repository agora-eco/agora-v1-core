// SPDX-License-Identifier: MIT
/** 
    Secondary txns + royalties. Users can both list, trade, and sell market-purchased items on this marketplace
*/

pragma solidity ^0.8.0;

import {Market} from "../base/Market.sol";

contract Marketplace is Market {
    uint256 public marketplaceFee;

    constructor(
        string memory _symbol,
        string memory _name,
        uint256 _marketplaceFee
    ) Market(_symbol, _name) {
        marketplaceFee = _marketplaceFee;
    }

    function adjustFees(uint256 fees) external isAdmin {
        require(fees >= 0 && fees <= 100, "fees outside of range");
        marketplaceFee = fees;
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
            quantity * product.price * 10**18 <= msg.value,
            "insufficient funds"
        );

        product.quantity -= quantity;
        _catalog[productCode] = product;

        payable(owner).transfer(product.price);

        emit Purchase(
            productCode,
            product.name,
            quantity,
            product.price * quantity,
            tx.origin
        );
    }
}
