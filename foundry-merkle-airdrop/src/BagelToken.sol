// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BagelToken is ERC20, Ownable {
    // This contract will implement the ERC20 token standard.
	constructor() ERC20("Bagel", "BAGEL") Ownable(msg.sender) {
        // The initial supply will be managed by the owner minting tokens as needed,
        // rather than minting a fixed supply at deployment.
    }
​	
	// allowing the owner to mint tokens on demand
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

}