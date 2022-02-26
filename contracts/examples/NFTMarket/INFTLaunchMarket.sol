// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

/**
 * @dev Example market built off the Agora market standard that supports NFT sales.
 */
interface INFTLaunchMarket {
    function setMaxPerOwner(uint256 _maxPerOnwer) external;
}
