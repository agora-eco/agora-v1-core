// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Treasury {
    uint256 balance = 0;

    /*
     */
    function deposit() external {}

    /*
     */
    function withdraw(uint256 amount) external {
        payable(tx.origin).transfer(amount);
    }
}
