// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
​
contract MerkleAirdrop {
    // Purpose:
    // 1. Manage a list of addresses and corresponding token amounts eligible for the airdrop.
    // 2. Provide a mechanism for eligible users to claim their allocated tokens.

	address[] claimers;

	// function claim(address) external {
	// 	for (uint i = 0; i < claimers.length; i++) {
			// che if the account is in the claiumers
			// if you do this you have to loop every time and spend too much gas
	//  Merkle Proofs prove some piece of data is in a group of data
	
}