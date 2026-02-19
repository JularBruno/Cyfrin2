// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract TokenAndAirDropDeployer is Script {
	function run() public returns (BagelToken token, MerkleAirdrop airdrop) {

	}
}