// SPDX-License-Identifier: MIT

// not really that strict when following conventions

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Raffle} from "src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is CodeConstants, Test {

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

    // 
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

    /* 
    CHECK UPKEEP 
    */
    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); 
        // Act 
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }


    function testCheckUpKeepReturnsFalseIfRaffleIsntOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); 
        raffle.performUpkeep();
        // Act 
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    // Challenge
    // testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed
    // testCheckUpkeepReturnsTrueWhenParametersGood

    function testCheckUpKeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Act 
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); 

        // Act 
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded);
    }

    /* 
        PERFORM UPKEEP
     */

    function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); 
        // Act / Assert
        // could do an assert success, but this works, at failing it is the same as an assert
        raffle.performUpkeep();
    }

    // test it reverts with correct error
    function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public { 
        // Arrange
        uint256 currentBalance = 0; 
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        currentBalance = currentBalance + entranceFee;
        numPlayers = 1;

        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, 
            currentBalance, numPlayers, rState)
        );
        raffle.performUpkeep();
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1); 
        _;
    }

    // REQUEST emited events
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        // Arrange // finally used modifier
        
        // Act 
        vm.recordLogs(); // remmember you can check foundry book docs
        raffle.performUpkeep(); // keep track of all logs of this function

        // super special cheatcode 
        Vm.Log[] memory entries = vm.getRecordedLogs(); // entries array a lot of logs
        
        // TOPICS in entries are indexed paremeters in an event!
        // entries[1] because vrf emits an event first and .topics[1] because 0 is used for sth else
        bytes32 requestId = entries[1].topics[1];
        
        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0); // just checking if any emit
        
        assert(uint256(raffleState) == 1);

        //     ├─ [0] VM::getRecordedLogs() in test has the log of VRF contract
    }

    /* 
        FULFILL RANDOM WORDS
     */

    modifier skipFork() {
        if(block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }
 
    function testFullfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEntered skipFork {
        // Arrange // Act // Assert
        // check again vrf coordinator to check error
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        // requestId and consumer, but we need to test many requests ids not just random one
        // randomRequestId FUZZ
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

    /* END TO END big ass test */
    function testFullfillRandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered skipFork {
        // Arrange
        uint256 additionalEntrants = 3;
        uint256 startingIndex = 1; // this to not start with address 0
        address expectedWinner = address(1); // not sure about the math behind this

        for (uint i = startingIndex; i <startingIndex+ additionalEntrants; i++) {
            address newPlayer = address(uint160(i)); // convert any number into address very CONSOLE
            hoax(newPlayer, 1 ether); // prank and found remmember
            raffle.enterRaffle{value: entranceFee}();
        }
        
        uint256 startingTimeStamp = raffle.getLastTimestamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        // Act 
        vm.recordLogs();
        raffle.performUpkeep(); // kick chainlink vrf
        Vm.Log[] memory entries = vm.getRecordedLogs();

        bytes32 requestId = entries[1].topics[1];

        // now we call vrf coordinator to mock the call
        // just like calling the get random word
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimestamp();
        uint256 prize = entranceFee * (additionalEntrants + 1);

        assert(recentWinner == expectedWinner);
        assert(uint256(raffleState) == 0);
        assert(winnerBalance == winnerStartingBalance + prize);
        assert(endingTimeStamp > startingTimeStamp);
        // so this failed because vrf balance was not enough, so in interactions we funded the subscription with more money
    }


    
}