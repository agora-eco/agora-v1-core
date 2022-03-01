// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

/**
 * @dev Example market built off the Agora market standard that supports NFT sales.
 */
interface ITokenSaleMarket {
    function setMaxPerOwner(uint256 maxPerOwner_) external;

    function setMaxSupply(uint256 maxSupply_) external;

    function maxPerOwner() external view returns (uint256);

    function maxSupply() external view returns (uint256);
}
