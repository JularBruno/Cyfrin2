// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockRouter {
    function isChainSupported(uint64) external pure returns (bool) { return true; }
}