//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";

contract DeployFundMe is Script {
    // address mockPriceFeed = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function run() external returns (FundMe) {
        vm.startBroadcast();
        // new FundMe(mockPriceFeed);
        FundMe fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        vm.stopBroadcast();
        return fundMe;
    }  

}