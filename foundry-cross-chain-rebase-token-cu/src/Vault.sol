// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IRebaseToken } from "./interfaces/IRebaseToken.sol";

/**
 * @title Vault
 * @author jular
 * @notice This is a vault that allows users to deposit and withdraw ETH
*/
contract Vault {
    // we need to pass the token address to the constructor
    // create a deposit function that mints tokens to the user equal to the amount of ETH the user has sent
    // create a redeem function burns tokens from the user and send the user ETH
    // create a way to add rewards to the vault
    IRebaseToken private immutable i_rebaseToken;

    error VAULT__RedeemFailed();

    event Deposit(address indexed user, uint256 amount); // index or sort event by variable 
    event Redeem(address indexed user, uint256 amount);

    constructor(IRebaseToken _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    // fallback functoin
    // send rewards to te vault (irl this should be rewards that unlock linearly, like staking or lending or borrowing, or based on the vault values)
    // just rewards enough to distribute
    receive() external payable {}

   /**
    * @notice Allows users to deposit ETH into the vault and mint rebase tokens in return
    */ 
    function deposit() external payable { // payable for sending eth remmember
        // 1. we need to use the amount of ETH the user has sent to mint tokens to the user
        // 2. emit event

        // interface is required here IRebaseToken(i_rebaseToken)
        uint256 interestRate = i_rebaseToken.getInterestRate();
        i_rebaseToken.mint(msg.sender, msg.value, interestRate); // message.value gets te value of the msg.sender transaction!!!
        // we can mint when bridging
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to redeem their rebase tokens for ETH
     * @param _amount The amount of rebase tokens to redeem
     */
    function redeem(uint256 _amount) external {
        if(_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }

        // 1. burn tokens from the user
        i_rebaseToken.burn(msg.sender, _amount);
        // 2. send the user ETH
        // payable(msg.sender).transfer(_amount); // cast address to be payable, and all payable addresses have the method transfer
        (bool success, ) = payable(msg.sender).call{value: _amount}(""); // LOW LEVEL CALL is better than above
        if (!success) {
            revert VAULT__RedeemFailed();
        }

        emit Redeem(msg.sender, _amount);
    }


    /**
     * GETTERS
     */

    /**
     * @notice Get the address of the rebase token
     * @return The address of the rebase token
     */
    function getRebaseTokenAddress() external view returns(address) {
        return address(i_rebaseToken);
    }

}