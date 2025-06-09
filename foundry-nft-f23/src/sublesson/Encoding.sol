// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

// remmember to check cheatsheet https://docs.soliditylang.org/en/latest/cheatsheet.html

contract Encoding {
    function combineStrings() public pure returns(string memory) {
        // 0.8.12 + // string.concat works
        return string(abi.encodePacked("Hi Mom! ", "Miss you!")); // encoded both strings into its bytes form, because abi.encodePacked returns a bytes object, and we are typecasting it because wraping with string
    }

    function encodeNumber() public pure returns(bytes memory) { // what number looks like in binary
        bytes memory number = abi.encode(1); // abi is not just inputs and outputs to interact, its the aplication binary interface
        return number;
    }

    function encodeString() public pure returns(bytes memory) { 
        bytes memory someString = abi.encode("some string"); // this result is 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000b736f6d6520737472696e67000000000000000000000000000000000000000000
        return someString;
    }

    function encodeStringPacked() public pure returns(bytes memory) {
        bytes memory someString = abi.encodePacked("some string"); // encode can be compressed with encode packed, it even saves gas! also useful for typecasting
        return someString;
    } 

    function encodeStringBytes() public pure returns(bytes memory) {
        bytes memory someString = bytes("some string"); //
        return someString;
    } 

    function decodeString() public pure returns(string memory) {
        string memory someString = abi.decode(encodeString(), (string)); // Types can be a list
        return someString;
    }

    function multiEncode() public pure returns(bytes memory) {
        bytes memory someString = abi.encode("some string" , "its bigger!");
        return someString;
    }

    function multiDecode() public pure returns(string memory, string memory) {
        (string memory someString, string memory someOtherString) = abi.decode(multiEncode(), (string, string));
        return (someString, someOtherString);
    }

    function multiEncodePacked() public pure returns(bytes memory) {
        bytes memory someString = abi.encodePacked("some string" , "its bigger!"); // decoded would work since its packed encoding!!!
        return someString;
    }

    // This doesn't work!
    function multiDecodePacked() public pure returns (string memory) {
        string memory someString = abi.decode(multiEncodePacked(), (string));
        return someString;
    }

    function multiStringCastPacked() public pure returns(string memory) {
        string memory someString = string(multiEncodePacked());
        return someString;
    }

    // githbub notes https://github.com/Cyfrin/foundry-nft-cu/blob/main/src/sublesson/Encoding.sol

    // As of 0.8.13, you can now do `string.concat(string1, string2)`

    // This abi.encoding stuff seems a little hard just to do string concatenation... is this for anything else?
    // Why yes, yes it is.
    // Since we know that our solidity is just going to get compiled down to this binary stuff to send a transaction...

    // We could just use this superpower to send transactions to do EXACTLY what we want them to do...

    // Remeber how before I said you always need two things to call a contract:
    // 1. ABI
    // 2. Contract Address?
    // Well... That was true, but you don't need that massive ABI file. All we need to know is how to create the binary to call
    // the functions that we want to call.

    // Solidity has some more "low-level" keywords, namely "staticcall" and "call". We've used call in the past, but
    // haven't really explained what was going on. There is also "send"... but basically forget about send.

    // call: How we call functions to change the state of the blockchain.
    // staticcall: This is how (at a low level) we do our "view" or "pure" function calls, and potentially don't change the blockchain state.

    // When you call a function, you are secretly calling "call" behind the scenes, with everything compiled down to the binary stuff
    // for you. Flashback to when we withdrew ETH from our raffle:

    function withdraw(address recentWinner) public {
        (bool success,) = recentWinner.call{value: address(this).balance}(""); // updated directly value in solidity, this literally send money and sends data empty. Same a castcall from remix 
        require(success, "Transfer Failed");
    }

    // Remember this?
    // - In our {} we were able to pass specific fields of a transaction, like value.
    // - In our () we were able to pass data in order to call a specific function - but there was no function we wanted to call!
    // We only sent ETH, so we didn't need to call a function!
    // If we want to call a function, or send any data, we'd do it in these parathesis!

    // Let's look at another contract to explain this more...
}