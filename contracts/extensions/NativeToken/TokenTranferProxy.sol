// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./ITokenTransferProxy.sol";

/**
 * @dev Example market built off the Agora market standard that supports NFT sales.
 */
contract TokenTransferProxy is ITokenTransferProxy {
    using SafeERC20 for IERC20;

    function approve(IERC20 token) external virtual override {
        token.approve(address(this), token.totalSupply());
    }

    function transferToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) external virtual override {
        token.transferFrom(from, to, amount);
    }
}
