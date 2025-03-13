// SPDX-License-Identifier: MIT

// not really that strict when following conventions

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";

contract RaffleTest is Test {

    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 keyHash;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);

    function setUp() external {
        DeployRaffle deployer =  new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee; 
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        keyHash = config.keyHash;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;

        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    // start with raffle state as open, cool I wanted to check if this works
    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /* 
    ENTER RAFFLE
     */

    function testRaffleRevertsWhenYouDontPayEnough() public {
        // Arrange
        vm.prank(PLAYER);
        // Act // Assert
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        // Arrange
        vm.prank(PLAYER);
        // Act 
        raffle.enterRaffle{value: entranceFee}();
        // Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
        
    }

    function testEnteringRaffleEmitsEvent() public {
        // expecte emit tests
        // // indexed parameters require false

        // Arrange
        vm.prank(PLAYER);
        // Act 
        vm.expectEmit(true, false, false, false, address(raffle)); // false, because no aditional parameter 
        // requires event copy pasted
        emit RaffleEntered(PLAYER); // the event would be different in case there is another player
        // Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testDontAllowPlayersWhileRaffleIsCalculating() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        // change block timestamp, we pass the deadline or interval here
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); // one new block has been added, also for timestamp

        raffle.performUpkeep();

        // Act // Assert
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRaffle() public {
        // Arrange
        vm.prank(PLAYER);
        // Act 
        // Assert
    }
}