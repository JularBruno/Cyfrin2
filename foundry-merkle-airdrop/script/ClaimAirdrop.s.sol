// script/interact.s.sol
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MerkleAirdrop.sol";
import { tryRecover } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract ClaimAirdrop is Script {
    // Config
    address constant MERKLE_AIRDROP_CONTRACT = 0x71725E7734CE288F83E7E1B143E90b3F0512;
    address constant CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 constant CLAIMING_AMOUNT = 25 * 1e18;

    bytes32[] proof;

    function run(uint8 v_sig, bytes32 r_sig, bytes32 s_sig) external {
        // Example:
        // proof = new bytes32;
        // proof[0] = ...;
        // proof[1] = ...;

        vm.startBroadcast();

		(bytes32 r, bytes32 s, uint8 v) = tryRecover();

        MerkleAirdrop(MERKLE_AIRDROP_CONTRACT).claim(
            CLAIMING_ADDRESS,
            CLAIMING_AMOUNT,
            proof,
            v_sig,
            r_sig,
            s_sig
        );

        vm.stopBroadcast();
    }
}