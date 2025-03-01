// Fund
// Withdraw

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;
    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();

        console.log("Funded FundMe with %s", SEND_VALUE);
    }
    
    function run() external {
        // foundry-devops for most recently deployed contract
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid); // read run latest from broadcast
        fundFundMe(mostRecentlyDeployed);
    }
}


contract WithdrawFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }
    
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid); // read run latest from broadcast
        withdrawFundMe(mostRecentlyDeployed);
    }
}