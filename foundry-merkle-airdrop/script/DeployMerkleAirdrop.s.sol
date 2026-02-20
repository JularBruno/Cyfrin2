// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";
import { BagelToken } from "../src/BagelToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private s_merkleRoot = 0xd12c51d9bf33a2f5aff9fc1d0651f2ad5b7bca0606c73d597f4db93a2f516093;
    uint256 private s_amountToTransfer = 4 * 25 * 1e18; // 4 users, 25 tokens each

	function run() external returns (MerkleAirdrop, BagelToken) {
		return deployMerkleAirdrop();
	}

	function deployMerkleAirdrop() public returns (MerkleAirdrop, BagelToken) {
		vm.startBroadcast();
	
		BagelToken token = new BagelToken();
		MerkleAirdrop airdrop = new MerkleAirdrop(s_merkleRoot, IERC20(address(token)));
	
		// Mint tokens to the deployer (owner of the token contract by default)
		token.mint(token.owner(), s_amountToTransfer);
		// Transfer tokens from the deployer to the airdrop contract
		token.transfer(address(airdrop), s_amountToTransfer);
	
		vm.stopBroadcast();
		return (airdrop, token);
	}
}