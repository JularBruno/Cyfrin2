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

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title Sample Raffle contract
 * @author bruno
 * @notice this contrat is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* Errors */
    error Raffle__SendMoreToEnterRaffle(); // to know where revert comes from, add contract name prefix with __
    error Raffle__TransferFailed();

    uint256 private immutable i_entranceFee;
    // @dev interval between lottery rounds. Duration of lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players; // syntax for making an address array payable
    uint256 private immutable s_lastTimeStamp;
    // chainlink vars
    bytes32 private immutable i_keyHash;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant NUM_WORDS = 1;


    address private s_recentWinner;

    /* Events */
    event RaffleEntered(address indexed player);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 keyHash,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = keyHash;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
    }

    function enterRaffle() external payable {
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

    // get random number, use random number to pick player, automatically called
    // smart contracts cant automate themselves
    function pickWinner() external {
        // check time passed, current time according to blockchain
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        // get our random number, difficult on deterministic machines

        // watch the struct for the parameters, we are passing it here like an object
        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({ // name of contract name of struct
            keyHash: i_keyHash, // max gas in wei
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    // is virtual in contract, so we override it, is required. Is Internal the chainlink node will call rawFulfillRandomWords
    // what to do after getting random words
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        // modular operator, used to pick the random number and modulate it by the amount of users
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        (bool success, ) = recentWinner.call{value: address(this).balance}(""); // pay the user all contract balance
        if(!success) {
            revert Raffle__TransferFailed();
        }

    }

    /* Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
