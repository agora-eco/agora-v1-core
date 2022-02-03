// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProduct {
    event Create();
    event Adjust();
    event Purchase();

    function create() external;

    function adjust() external;

    function purchase() external;
}
