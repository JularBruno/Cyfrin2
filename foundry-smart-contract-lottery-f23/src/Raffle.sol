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
    /* Errors */
    error Raffle__SendMoreToEnterRaffle(); // to know where revert comes from, add contract name prefix with __

    uint256 private immutable i_entranceFee; 
    address payable[] private s_players; // syntax for making an address array payable

    /* Events */
    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough eth") // this is not gas efficient because of string
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle()); // newer versions!! need special compiler, and les gass eficient because low level stuff
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle(); // always defaul to this kind of ifs
        }

        // keep track of all raffle players
        // default for mapping for data structures, but we are using the array s_players
        s_players.push(payable(msg.sender)); // again payable to push payable address
        // have to emit event
        emit RaffleEntered(msg.sender);
        // 
    }

    function pickWinner() public {
        
    }

    /* Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    

}