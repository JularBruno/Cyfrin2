// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol"; // For it to be considered a Foundry script and to be able to access the extended functionality Foundry is bringing to the table we need to import `Script`
import {SimpleStorage} from "../src/SimpleStorage.sol";

contract DeploySimpleStorage is Script { // Every script needs a main function, which, according to the best practice linked above is called `run`
    function run() external returns (SimpleStorage) {
        vm.startBroadcast(); // vm cheatcode is a forge utility too
        // here put all the transactions to send, very usable for testing
        SimpleStorage simpleStorage = new SimpleStorage();
        vm.stopBroadcast();
        return simpleStorage;
    }
}
