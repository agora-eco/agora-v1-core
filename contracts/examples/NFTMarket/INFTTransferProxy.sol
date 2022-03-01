// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Example market built off the Agora market standard that supports NFT sales.
 */
interface INFTTransferProxy {
    function approve(IERC721 token) external;

    function transferToken(
        IERC721 token,
        address from,
        address to,
        uint256 amount
    ) external;
}
