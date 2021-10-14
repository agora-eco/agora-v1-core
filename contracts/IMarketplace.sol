// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IMarketplace {
    function purchase(uint256 _merchantId, string memory _productId) external {}

    function refund(uint256 _orderId) external {}
}
