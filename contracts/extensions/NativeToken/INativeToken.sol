// SPDX-License-Identifier: MIT
/**
    One-way txns only. No reselling facilitated via market, no royalties, etc.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokenTransferProxy.sol";

/**
 * @dev Example market built off the Agora market standard that supports NFT sales.
 */
interface INativeToken {
    function setToken(IERC20 token_) external;

    function setTokenTransferProxy(ITokenTransferProxy transferProxy_) external;

    function token() external view returns (IERC20);

    function tokenTransferProxy() external view returns (ITokenTransferProxy);

    function approveProxySpending() external;
}
