// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BasicNft is ERC721 {

    uint256 private s_tokenCounter;
    mapping(uint256 => string) private s_tokenIdToUri;

    constructor() ERC721("Dogie", "DOG") {
        s_tokenCounter = 0; // update on mint
    }

    function mintNft(string memory tokenUri) public { // each URI need to have the location, endpoint that returns the metadata 
        s_tokenIdToUri[s_tokenCounter] = tokenUri;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter++;
    }

    function tokenURI(uint256 tokenId) public view override 
    returns(string memory) { // It has virtual so it can be overwritten
        // returns string of ie ipfs witht the image, or onchain uri
        return s_tokenIdToUri[tokenId];

    }
}