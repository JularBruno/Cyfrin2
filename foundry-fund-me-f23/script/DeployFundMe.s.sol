// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
    // address mockPriceFeed = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function run() external returns (FundMe) {
        HelperConfig helperConfig = new HelperConfig(); // before broadcast for not using gas, this is simulated
        address ethUsdPriceFeed = helperConfig.activeNetworkConfig(); // this can be a construct if many

        vm.startBroadcast();
        // new FundMe(mockPriceFeed);

        // mock 
        // FundMe fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }  

}