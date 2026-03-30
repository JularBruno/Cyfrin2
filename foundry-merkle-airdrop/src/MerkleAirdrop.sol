// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
// ​import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// IERC20.transfer(address recipient, uint256 amount) function has a known quirk: it returns a boolean indicating success or failure, but it doesn't necessarily revert the transaction if the transfer fails
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop is EIP712 {
	using SafeERC20 for IERC20;
    // Purpose:
    // 1. Manage a list of addresses and corresponding token amounts eligible for the airdrop.
    // 2. Provide a mechanism for eligible users to claim their allocated tokens.
    
	/* 
	* Errors
	*/
    error MerkleAirdrop_InvalidProof();
	error MerkleAirdrop_AlreadyClaimed();
	error MerkleAirdrop_InvalidSignature();
	error __MyScriptName_InvalidSignatureLength(); // Use a script-specific name


	/* 
	* State Variables 
	*/
	bytes32 private immutable i_merkleRoot;
	IERC20 private immutable i_airdropToken;
	mapping(address claimant => bool) private s_hasClaimed; //  Declaring a Mapping to Track Claimed Addresses
	
	// EIP-712 Typehash for our specific claim structure
    // "AirdropClaim(address account,uint256 amount)"
	bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account,uint256 amount)");
    // It's good practice to pre-compute this hash: keccak256("AirdropClaim(address account,uint256 amount)")

    // The struct representing the data to be signed
    struct AirdropClaim {
        address account;
        uint256 amount;
    }

	/* 
	* Events
	*/
	event Claim(address indexed account, uint256 amount); // (Note: Marking account as indexed allows for easier filtering of these events off-chain.)
	

	// address[] claimers;
	// function claim(address) external {
	// 	for (uint i = 0; i < claimers.length; i++) {
			// che if the account is in the claiumers
			// if you do this you have to loop every time and spend too much gas

	//  Merkle Proofs prove some piece of data is in a group of data
	constructor(bytes32 merkleRoot, IERC20 airdropToken) 
		EIP712("MerkleAirdrop", "1") // Initialize EIP712 with contract name and version
	{
		i_merkleRoot = merkleRoot;
		i_airdropToken = airdropToken;
	}

	// Function to compute the EIP-712 digest
    function getMessage(address account, uint256 amount) public view returns (bytes32) {
        // 1. Hash the struct instance according to EIP-712 struct hashing rules
		bytes32 structHash = keccak256(abi.encode(
			MESSAGE_TYPEHASH,
			AirdropClaim({account: account, amount: amount})
		));
		// 2. Combine with domain separator using _hashTypedDataV4 from EIP712 contract
        // _hashTypedDataV4 constructs the EIP-712 digest:
        // keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash))
		return _hashTypedDataV4(structHash);
    }

	function _isValidSignature(
		address expectedSigner, // The address we expect to have signed (claim.account)
		bytes32 digest,         // The EIP-712 digest calculated by getMessage
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal pure returns (bool) {
		// Attempt to recover the signer address from the digest and signature components
		// ECDSA.tryRecover is preferred for security, openzepelin package
		(address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);

		// Check two things:
		// 1. Recovery was successful (actualSigner is not the zero address).
		// 2. The recovered signer matches the expected signer (the 'account' parameter).
		return actualSigner != address(0) && actualSigner == expectedSigner;
	}

	function claim(
		address account,          // The recipient/signer address
		uint256 amount,           // The amount being claimed
		bytes32[] calldata merkleProof, // Merkle proof for the claim
		uint8 v,                  // Signature recovery ID
		bytes32 r,                // Signature component r
		bytes32 s                 // Signature component s
	) external {
		// CHECK 1: Has this account already claimed?
		if (s_hasClaimed[account]) { // Remmember custom errors are very gas efficient
			revert MerkleAirdrop_AlreadyClaimed();
		}

		// check 2: Construct the digest the user should have signed
		bytes32 digest = getMessage(account, amount);
		
		// Verify the signature
		if (!_isValidSignature(account, digest, v, r, s)) {
			revert MerkleAirdrop_InvalidSignature();
		}

		// CHECK 3: Is the Merkle proof valid for this account and amount?
		// calculatine using the account and the amount the hash using the leafe mode
		// This implementation double-hashes the abi.encoded data.
		// Consistency between off-chain leaf generation and on-chain verification is paramount, supremly important.
		bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

		// If MerkleProof.verify returns false (meaning the proof is invalid for the given leaf and root), the if condition (!MerkleProof.verify(...)) becomes true, and the transaction reverts
		if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
			revert MerkleAirdrop_InvalidProof();
		}

		// EFFECT: Update state to mark this account as claimed.
		// CORRECT PLACEMENT - update state BEFORE external call
    	s_hasClaimed[account] = true; // Updating Claim Status and the Importance of Order (Checks-Effects-Interactions)

		// INTERACTION: Emit event and transfer tokens.
		emit Claim(account, amount);
		i_airdropToken.safeTransfer(account, amount);

	}

	/**
	 * @notice Splits a 65-byte concatenated signature (r, s, v) into its components.
	 * @param sig The concatenated signature as bytes.
	 * @return v The recovery identifier (1 byte).
	 * @return r The r value of the signature (32 bytes).
	 * @return s The s value of the signature (32 bytes).
	 */
	function splitSignature(bytes memory sig)
		public
		pure
		returns (uint8 v, bytes32 r, bytes32 s)
	{
		// Standard ECDSA signatures are 65 bytes:
		// r (32) + s (32) + v (1)
		if (sig.length != 65) {
			revert __MyScriptName_InvalidSignatureLength();
		}

		assembly {
			// r = first 32 bytes
			r := mload(add(sig, 0x20))

			// s = next 32 bytes
			s := mload(add(sig, 0x40))

			// v = first byte of next 32 bytes
			v := byte(0, mload(add(sig, 0x60)))
			
			// EIP-155: With EIP-155 (transaction replay protection on different chains), v values became chain-specific: chain_id * 2 + 35 or chain_id * 2 + 36.
			// if (v < 27) v += 27;

		}
	}

	/**
	 * GETTER FUNCTIONS
	 */
	function getMerkleRoot() external view returns (bytes32) {
		return i_merkleRoot;
	}

	function getAirdropToken() external view returns (IERC20) {
		return i_airdropToken;
	}
}