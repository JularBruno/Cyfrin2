// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";

contract SplitSignature is Script {
    error SplitSignatureScript_InvalidSignatureLength();

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // Signature must be 65 bytes: r (32) + s (32) + v (1)
        if (sig.length != 65) {
            revert SplitSignatureScript_InvalidSignatureLength();
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function run() external {
        string memory sigString = vm.readFile("signature.txt");
        bytes memory sigBytes = vm.parseBytes(sigString);

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sigBytes);

        console.log("v value:");
        console.log(v);

        console.log("r value:");
        console.logBytes32(r);

        console.log("s value:");
        console.logBytes32(s);
    }
}