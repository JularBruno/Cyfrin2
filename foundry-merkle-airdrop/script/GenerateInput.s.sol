// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

contract GenerateInput is Script {
    string constant FILE_PATH = "script/target/input.json";

    function run() external {
        // Define airdrop data
        string[] memory types = new string[](2);
        types[0] = "address";
        types[1] = "uint";

        uint256 amount = 2500 * 1e18; // Example amount

        address[] memory whitelist = new address[](4);
        whitelist[0] = 0x6CA6D1e2D5347bfaB1d91E883F1915560E891290;
        whitelist[1] = 0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B; // Example addresses
        whitelist[2] = 0x1Db3439a222C519ab44bb1144fC28167b4Fa6EE6;
        whitelist[3] = 0x0e466e7519A469f20168796a0807b758a2339791;

        string memory json = createJSON(types, whitelist, amount);
        vm.writeFile(FILE_PATH, json);
        console.log("Successfully wrote input.json to %s", FILE_PATH);
    }

    function createJSON(
        string[] memory types,
        address[] memory whitelist,
        uint256 amount
    ) internal pure returns (string memory) {
        string memory json = "{";

        // Add types
        json = string.concat(json, "\"types\": [");
        for (uint i = 0; i < types.length; i++) {
            json = string.concat(json, "\"", types[i], "\"");
            if (i < types.length - 1) {
                json = string.concat(json, ", ");
            }
        }
        json = string.concat(json, "], ");

        // Add count
        json = string.concat(
            json,
            "\"count\": ",
            vm.toString(whitelist.length),
            ", "
        );

        // Add values
        json = string.concat(json, "\"values\": {");
        for (uint i = 0; i < whitelist.length; i++) {
            json = string.concat(
                json,
                "\"",
                vm.toString(i),
                "\": {",
                "\"0\": \"",
                vm.toString(whitelist[i]),
                "\", ",
                "\"1\": \"",
                vm.toString(amount),
                "\"}"
            );
            if (i < whitelist.length - 1) {
                json = string.concat(json, ", ");
            }
        }
        json = string.concat(json, "}}");
        return json;
    }
}