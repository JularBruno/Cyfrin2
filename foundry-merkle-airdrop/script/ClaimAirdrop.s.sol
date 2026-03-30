// script/interact.s.sol
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MerkleAirdrop.sol";
import { tryRecover } from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract ClaimAirdrop is Script {
    // Config
    address constant MERKLE_AIRDROP_CONTRACT = 0x71725E7734CE288F83E7E1B143E90b3F0512;
    address constant CLAIMING_ADDRESS = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    uint256 constant CLAIMING_AMOUNT = 25 * 1e18;

	bytes private SIGNATURE = hex"0x12e145324b60cd4d302bfad59f72946d45ffad8b9fd608e672fd7f02029de7c438cfa0b8251ea803f361522da811406d441df04ee99c3dc7d65f8550e12be2ca1c";

    bytes32[] proof;

    function run(uint8 v_sig, bytes32 r_sig, bytes32 s_sig) external {
        // Example:
        // proof = new bytes32;
        // proof[0] = ...;
        // proof[1] = ...;

        vm.startBroadcast();

		// (bytes32 r, bytes32 s, uint8 v) = tryRecover(SIGNATURE);

		(uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
		MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);

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