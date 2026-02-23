// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MyEIP712Contract is EIP712 {
    // Define the struct for the message
    struct Message {
        string message;
    }

    // Calculate the TYPEHASH for the Message struct
    // keccak256("Message(string message)")
    bytes32 public constant MESSAGE_TYPEHASH = 0xf30f2840588e47605f8476d894c1d95d7220f7eda638ebb2e21698e5013de90a; // Precompute this

    constructor(string memory name, string memory version) EIP712(name, version) {}

    function getMessageHash(string memory _message) public view returns (bytes32) {
        // Calculate hashStruct(message)
        bytes32 structHash = keccak256(abi.encode(
            MESSAGE_TYPEHASH,
            keccak256(bytes(_message)) // EIP-712 requires hashing string/bytes members
        ));
        
        // _hashTypedDataV4 constructs the final EIP-712 digest:
        // keccak256(abi.encodePacked(0x19, 0x01, domainSeparator, structHash))
        return _hashTypedDataV4(structHash);
    }

    function getSignerOZ(bytes32 digest, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        // Use ECDSA.tryRecover for safer signature recovery
        (address signer, ECDSA.RecoverError error, ) = ECDSA.tryRecover(digest, _v, _r, _s); // ecrecover equivalent of openzeppelin
        
        // Optional: Handle errors explicitly
        // require(error == ECDSA.RecoverError.NoError, "ECDSA: invalid signature");
        if (error != ECDSA.RecoverError.NoError) {
            // Handle specific errors or revert
            if (error == ECDSA.RecoverError.InvalidSignatureLength) revert("Invalid sig length");
            if (error == ECDSA.RecoverError.InvalidSignatureS) revert("Invalid S value");
            // ... etc. or a generic revert
            revert("ECDSA: invalid signature");
        }
        
        return signer;
    }

    function verifySignerOZ(
        string memory _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        address expectedSigner
    )
        public
        view
        returns (bool)
    {
        bytes32 digest = getMessageHash(_message);
        address actualSigner = getSignerOZ(digest, _v, _r, _s);
        require(actualSigner == expectedSigner, "Signer verification failed");
        require(actualSigner != address(0), "Invalid signer recovered"); // Additional check
        return true;
    }
}