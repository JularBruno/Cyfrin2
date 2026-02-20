// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { MerkleAirdrop } from "../src/MerkleAirdrop.sol";
import { DeployMerkleAirdrop } from "../script/DeployMerkleAirdrop.s.sol";
import { BagelToken } from "../src/BagelToken.sol";
import { ZkSyncChainChecker } from "lib/foundry-devops/src/ZkSyncChainChecker.sol"; // If using foundry-devops

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    // State variables
    MerkleAirdrop public airdrop;
    BagelToken public token;

    // This ROOT value is derived from your Merkle tree generation script
    // It will be updated later in the process
    // bytes32 public ROOT = 0x474d994c58e37b12085fdb7bc6bbc0d46cf1907b90de3b7fb883cf3636c8ebfb;

    bytes32 public ROOT = 0xd12c51d9bf33a2f5aff9fc1d0651f2ad5b7bca0606c73d597f4db93a2f516093;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18; // Example claim amount for the test user
    uint256 public AMOUNT_TO_SEND; // Total tokens to fund the airdrop contract

    // User-specific data
    address user;
    uint256 userPrivKey; // Private key for the test user

    // Merkle Proof for the test user
    // The structure (e.g., bytes32[2]) depends on your Merkle tree's depth
    // These specific values will be populated from your Merkle tree output
    bytes32 proofOne;
    bytes32 proofTwo;
    bytes32[2] public PROOF;

    function setUp() public {
        // 1. Deploy the ERC20 Token
		if (!isZkSyncChain()) { // This check is from ZkSyncChainChecker
			// Deploy with the script
			DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
			(airdrop, token) = deployer.deployMerkleAirdrop();
		} else {
			// Original manual deployment for ZKsync environments (or other specific cases)
			token = new BagelToken();
			// Ensure 'ROOT' here is consistent with s_merkleRoot in the script
			airdrop = new MerkleAirdrop(ROOT, token);
			// Ensure 'AMOUNT_TO_SEND' here is consistent with s_amountToTransfer in the script
			token.mint(address(this), AMOUNT_TO_SEND);
			token.transfer(address(airdrop), AMOUNT_TO_SEND);
		}

        // 2. Generate a Deterministic Test User
        // `makeAddrAndKey` creates a predictable address and private key.
        // This is crucial because we need to know the user's address *before*
        // generating the Merkle tree that includes them.
        (user, userPrivKey) = makeAddrAndKey("testUser");
   
        // 3. Deploy the MerkleAirdrop Contract
        // Pass the Merkle ROOT and the address of the token contract.
        airdrop = new MerkleAirdrop(ROOT, token);
   
        // 4. Fund the Airdrop Contract (Critical Step!)
        // The airdrop contract needs tokens to distribute.
        // Let's assume our test airdrop is for 4 users, each claiming AMOUNT_TO_CLAIM.
        AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
   
        // The test contract itself is the owner of the BagelToken by default upon deployment.
        address owner = address(this); // or token.owner() if explicitly set elsewhere
   
        // Mint tokens to the owner (the test contract).
        token.mint(owner, AMOUNT_TO_SEND);
   
        // Transfer the minted tokens to the airdrop contract.
        // Note the explicit cast of `airdrop` (contract instance) to `address`.
        token.transfer(address(airdrop), AMOUNT_TO_SEND);

        // Locate the Merkle proof specific to your user address in output.json. This will be an array of bytes32 hashes.
        proofOne = 0x2bc7bc0f0e2cc6b4f349fb598317c83fd701f46a2f104f6fdb44af1683572746;
        proofTwo = 0x056a8946e2bf511ff785ed93b55a36290b27f59371c9d3a025f5ccc29be4a008;
        PROOF = [proofOne, proofTwo];
    } // Key Point: A common pitfall is forgetting to fund the airdrop contract. If the MerkleAirdrop contract holds no tokens, claim attempts will naturally fail.

    function testSetup() public {
        console.log(user);
        
        console.logBytes32(airdrop.getMerkleRoot());

        // Just a placeholder test so forge finds it
        assert(address(token) != address(0));
        assert(address(airdrop) != address(0));

    }

    function testLeafGeneration() public {
        bytes32 computedLeaf = keccak256(bytes.concat(keccak256(abi.encode(user, AMOUNT_TO_CLAIM))));
        bytes32 expectedLeaf = 0x5c22b3319c305aa1689a9386137ec820cfb5c1068b6699db995bec4f913b3421;
        
        console.logBytes32(computedLeaf);
        console.logBytes32(expectedLeaf);
        
        assert(computedLeaf == expectedLeaf);
    }
   
    function testUsersCanClaim() public {
        // 1. Get the user's starting token balance
        uint256 startingBalance = token.balanceOf(user);
   
        // 2. Simulate the claim transaction from the user's address
        // `vm.prank(address)` sets `msg.sender` for the *next* external call only.
        vm.prank(user);
   
        // // Convert fixed-size array to dynamic array
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = PROOF[0];
        proof[1] = PROOF[1];

        // 3. Call the claim function on the airdrop contract
        airdrop.claim(user, AMOUNT_TO_CLAIM, proof);
   
        // 4. Get the user's ending token balance
        uint256 endingBalance = token.balanceOf(user);
   
        // For debugging, you can log the ending balance:
        console.log("User's Ending Balance: ", endingBalance);
   
        // 5. Assert that the balance increased by the expected claim amount
        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM, "User did not receive the correct amount of tokens");
    }

    function testUserNotIncludedCannotClaim() public {

        (address userNotIncluded, uint256 userNotIncludedKey) = makeAddrAndKey("testUserNotIncluded");

        vm.prank(userNotIncluded);
   
        // Convert fixed-size array to dynamic array
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = PROOF[0];
        proof[1] = PROOF[1];
        
        // Call the claim function on the airdrop contract and expect revert
        vm.expectRevert();
        airdrop.claim(userNotIncluded, AMOUNT_TO_CLAIM, proof);

    }


    function testClaimReentrancyFails() public {
    }
}