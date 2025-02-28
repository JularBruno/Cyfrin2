// buckle up as we unveil what separates the best developers from the rest: comprehensive, effective tests!
// `.t.` is a naming convention of Foundry, please use it.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import { FundMe } from "../src/FundMe.sol";
import { DeployFundMe } from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    uint256 favNumber = 0;
    bool greatCourse = false;

    FundMe fundMe;
    // address mockPriceFeed = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // this wasnt on the tutorial, just a mock address

    function setUp() external { // This function is always the first to execute whenever we run our tests. 
        favNumber = 1337;
        greatCourse = true;
        // console.log("This will get printed first!");

        // fundMe = new FundMe(mockPriceFeed); // state variable!
        // fundMe = new FundMe(); // 
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();

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

}