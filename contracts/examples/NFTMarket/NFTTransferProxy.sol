// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // replace with custom implementation
import "./INFTTransferProxy.sol";

/**
 * @dev Example market built off the Agora market standard that supports NFT sales.
 */
contract NftTransferProxy is INFTTransferProxy {
    function approve(IERC721 token) external virtual override {
        token.setApprovalForAll(address(this), true);
    }

    function transferToken(
        IERC721 token,
        address from,
        address to,
        uint256 tokenId
    ) external virtual override {
        token.safeTransferFrom(from, to, tokenId);
    }
}
