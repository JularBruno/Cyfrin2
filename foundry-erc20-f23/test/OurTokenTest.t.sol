// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {OurToken} from "../src/OurToken.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("bob");
    address alice = makeAddr("alice");

    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public  {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        // transferFrom -  is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
        // The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
        // etherscan has token approval checker

        uint256 initialAllowence = 1000;

        // bob approves alice to spend tokens on her behalf
        // update spendallownce
        vm.prank(bob);
        ourToken.approve(alice, initialAllowence);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount); // transfer from is different from transfer, it only goiws through if approved

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);
    }

    /* AI GENERATED */
    
    function testInitialSupply() public {
        assertEq(ourToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(ourToken)).mint(address(this), 1);
    }

    function testTransferTokens() public {
        uint256 amount = 10;

        // Fund bob first
        vm.prank(msg.sender);
        ourToken.transfer(bob, amount); // not sure why ai does this could easily found bob

        // Now Bob tries to transfer to himself (or another address)
        vm.prank(bob);
        ourToken.transfer(alice, amount);
        
        assertEq(ourToken.balanceOf(alice), amount);
    }

    function testApproveAndAllowance() public {
        uint256 allowanceAmount = 5000;
        vm.prank(msg.sender);
        ourToken.approve(bob, allowanceAmount);
        assertEq(ourToken.allowance(msg.sender, bob), allowanceAmount);
    }

    function testTransferFromWithAllowance() public {
        uint256 allowanceAmount = 5000;
        uint256 transferAmount = 3000;
        
        vm.startPrank(msg.sender);
        ourToken.approve(bob, allowanceAmount);
        vm.stopPrank();

        vm.prank(bob);
        ourToken.transferFrom(msg.sender, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.allowance(msg.sender, bob), allowanceAmount - transferAmount);
    }

    function testRevertsTransferMoreThanBalance() public {
        uint256 transferAmount = ourToken.balanceOf(msg.sender) + 1;
        vm.prank(msg.sender);
        vm.expectRevert();
        ourToken.transfer(bob, transferAmount);
    }

    function testRevertsTransferFromWithoutApproval() public {
        uint256 transferAmount = 1000;
        vm.expectRevert();
        ourToken.transferFrom(msg.sender, alice, transferAmount);
    }


}