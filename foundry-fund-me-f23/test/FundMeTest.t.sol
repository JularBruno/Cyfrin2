// buckle up as we unveil what separates the best developers from the rest: comprehensive, effective tests!
// `.t.` is a naming convention of Foundry, please use it.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import { FundMe } from "../src/FundMe.sol";
import { DeployFundMe } from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // uint256 favNumber = 0;
    // bool greatCourse = false;
    
    // cheatcodes forge-std
    address USER = makeAddr("user"); // needs funds
    
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    FundMe fundMe;

    // address mockPriceFeed = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // this wasnt on the tutorial, just a mock address

    function setUp() external { // This function is always the first to execute whenever we run our tests. 
        // favNumber = 1337;
        // greatCourse = true;
        // console.log("This will get printed first!");

        // fundMe = new FundMe(mockPriceFeed); // state variable!
        // fundMe = new FundMe(); // 
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

        vm.deal(USER, STARTING_BALANCE); // USER FUNDS
     } 

    // function testDemo() public { 
    //     assertEq(favNumber, 1337);
    //     assertEq(greatCourse, true);
    //     // console.log("This will get printed second!");
    //     // console.log("Updraft is changing lives!");
    //     // console.log("You can print multiple things, for example this is a uint256, followed by a bool:", favNumber, greatCourse);
    // }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        // assertEq(fundMe.i_owner(), msg.sender); // this wrong because contract is deployed on setup
        // assertEq(fundMe.i_owner(), address(this)); // removed this since updated Script on refactor
        assertEq(fundMe.i_owner(), msg.sender);
    }


    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        console.log('version ', version);
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        // cheatcodes foundry docs, assertions
        vm.expectRevert(); // the next line should revert
        fundMe.fund(); // no funds, 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        
        vm.prank(USER); // cheatcodes, environment, prank (this will be sent by USER)
        // cheatcodes foundry docs, assertions
        fundMe.fund{value: SEND_VALUE}(); // not msg.sender, is address(this)
        
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        // SETUP runs before each test!!!

        vm.prank(USER);

        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // tests should have minimum least code possible
    // organize test with test tree
    function testOnlyOwnerCanModify() public funded {
        // vm.prank(USER); 
        // fundMe.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);

    }

    function testWithDrawFromMultipleFunder() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // uint160 same bytes as an address
        uint160 startingFunderIndex = 1; // dont send 0 address!!

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // HOAX does vm.prank and then vm.deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();

            // fund the fundme
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act

        // uint256 gasStart = gasleft(); // gasLeft solidity
        // vm.txGasPrice(GAS_PRICE);

        // vm.prank(fundMe.getOwner());

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // tx: also built in solidity for transacton

        // console.log(gasUsed);

        vm.stopPrank();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);

    
    }


}