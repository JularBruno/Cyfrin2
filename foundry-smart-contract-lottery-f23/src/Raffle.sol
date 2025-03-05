// SPDX-License-Identifier: MIT
// Order of Layout

// Contract elements should be laid out in the following order:
// Pragma statements
// Import statements
// Events
// Errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Functions should be grouped according to their visibility and ordered:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view and pure


pragma solidity ^0.8.18;

/**
 * @title Sample Raffle contract
 * @author bruno
 * @notice this contrat is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {
    uint256 private immutable i_entranceFee; 

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {


    }

    function pickWinner() public {
        
    }

    /* Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    

}