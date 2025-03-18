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
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /* type declarations  */
    enum RaffleState {OPEN, CALCULATING} // best than bool for defining more things, all states are an int 0

    /* state variables */
    uint256 private immutable i_entranceFee;
    // @dev interval between lottery rounds. Duration of lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players; // syntax for making an address array payable
    uint256 private s_lastTimeStamp;
    RaffleState private s_raffleState;
    address private s_recentWinner;

    // chainlink vars
    bytes32 private immutable i_keyHash;
    bytes32 private immutable i_gasLane;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant NUM_WORDS = 1;

    /* Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);

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
        i_keyHash = keyHash;
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        
        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN; // equals to RaffleState(0)
    }

    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee, "Not enough eth") // this is not gas efficient because of string
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle()); // newer versions!! need special compiler, and les gass eficient because low level stuff
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle(); // always defaul to this kind of ifs
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }

        // keep track of all raffle players
        // default for mapping for data structures, but we are using the array s_players
        s_players.push(payable(msg.sender)); // again payable to push payable address
        // have to emit event
        emit RaffleEntered(msg.sender);
        //
    }

    /**
     * @dev This is the functoin that the CHainlink nodes will call to see
     * if the lottery is ready to have a winner picked.
     * The following should be true in order for upkeepNeeded to be true:
     * 1. Time interval has passed
     * 2. The lottery is open
     * 3. THe contract has ETH
     * 4. Implicitly, your subscription has LINK
     * @return upkeepNeeded - true if its time to restart the lottery
     */

    function checkUpkeep(
        // bytes calldata /* checkData */ // this can be used
        bytes memory /* checkData */ // refactored because sth
    )
        public
        view
        // ovveride // this was for actual CHanilink contract!
        returns (bool upkeepNeeded, bytes memory /* performData */) // THIS is a way to initialize function parameters!!! It even starts as false
    {
        // upkeepNeeded = true; // This will be automatically returned ie!!!!
        // upkeepNeeded = (block.timestamp - lastTimeStamp) > interval; // Example of Chainlink docs
        bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN; // also syntatic sugar for an if
        bool hasBalance = address(this).balance > 0; // if contract has players
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, ""); // makes an obvious return because is best
    }

    // get random number, use random number to pick player, automatically called
    // smart contracts cant automate themselves
    // function pickWinner() external {
    function performUpkeep() external {
        // check time passed, current time according to blockchain
        // if ((block.timestamp - s_lastTimeStamp) < i_interval) {
        //     revert();
        // }

        (bool upkeepNeeded, ) = checkUpkeep("");
        if(!upkeepNeeded) {
           revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

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

        // restrict people of entering if we are picknig the winner 
        uint256 requestId = 
        s_vrfCoordinator.requestRandomWords(request);

        // VRF Coordinator actually emits this event! Redundant, but easier to test
        emit RequestedRaffleWinner(requestId);
    }

    // Fulffill raffle
    // is virtual in contract, so we override it, is required. Is Internal the chainlink node will call rawFulfillRandomWords.
    // what to do after getting random words
    // CEI: Checks, effects, Interactions pattern
    function fulfillRandomWords(uint256, /* requestId */ uint256[] calldata randomWords) internal override {
        /*  Checks (requires, conditional) more gas efficient to revert early*/

        /* Effect (internal contract state) */

        // modular operator, used to pick the random number and modulate it by the amount of users
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        s_raffleState = RaffleState.OPEN; // change state after picking winner
        s_players = new address payable[](0); // restart array of players
        s_lastTimeStamp = block.timestamp; // restart raffle clock 
        
        emit WinnerPicked(s_recentWinner); // LOOK THIS is on effect

        /* Interactions (External Contract Interactions) */

        (bool success, ) = recentWinner.call{value: address(this).balance}(""); // pay the user all contract balance
        if(!success) {
            revert Raffle__TransferFailed();
        }
        

    }

    /* Getter Functions */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
    // there is a better way to this but we might want to have this functions actually
    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }
    
    function getRecentWinner() external view returns (address) {
        return s_recentWinner;
    }

    function getLastTimestamp() external view returns (uint256) {
        return s_lastTimeStamp;
    }
}
