// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
// ​import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// IERC20.transfer(address recipient, uint256 amount) function has a known quirk: it returns a boolean indicating success or failure, but it doesn't necessarily revert the transaction if the transfer fails
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
	using SafeERC20 for IERC20; 

    // Purpose:
    // 1. Manage a list of addresses and corresponding token amounts eligible for the airdrop.
    // 2. Provide a mechanism for eligible users to claim their allocated tokens.
    
	// State Variables
	bytes32 private immutable i_merkleRoot;
	IERC20 private immutable i_airdropToken;
	// Events
	event Claim(address indexed account, uint256 amount); // (Note: Marking account as indexed allows for easier filtering of these events off-chain.)
	// Errors
    error MerkleAirdrop_InvalidProof();

	//	address[] claimers;
	// function claim(address) external {
	// 	for (uint i = 0; i < claimers.length; i++) {
			// che if the account is in the claiumers
			// if you do this you have to loop every time and spend too much gas
	//  Merkle Proofs prove some piece of data is in a group of data
	constructor(bytes32 merkleRoot, IERC20 airdropToken) {
		i_merkleRoot = merkleRoot;
		i_airdropToken = airdropToken;
	}

	function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
		// calculatine using the account and the amount the hash using the leafe mode
		// This implementation double-hashes the abi.encoded data.
		// Consistency between off-chain leaf generation and on-chain verification is paramount, supremly important.
		bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
		// If MerkleProof.verify returns false (meaning the proof is invalid for the given leaf and root), the if condition (!MerkleProof.verify(...)) becomes true, and the transaction reverts
		if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
			revert MerkleAirdrop_InvalidProof();
		}
		emit Claim(account, amount);
		i_airdropToken.safeTransfer(account, amount);
	}
}