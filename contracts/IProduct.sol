// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProduct {
    function totalSupply(uint256 productId) external view returns (uint256);

    function totalSupply(string memory productCode)
        external
        view
        returns (uint256);
}
