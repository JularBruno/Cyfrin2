// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RebaseToken
 * @author jular
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in rewards.
 * @notice The interest rate in the smart contract can only decrease 
 * @notice Each will user will have their own interest rate that is the global interest rate at the time of depositing.
*/
contract RebaseToken is ERC20, Ownable, AccessControl {
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private constant PRECISION_FACTOR = 1e18; // 1e18 18 decimal precision, improved tolerance to 27 
    // rediud 1e18 because of overflow, higly precision 
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE"); // this how you create a role
    
    uint256 private s_interestRate = (5 * PRECISION_FACTOR) / 1e8; // 5% or 0.05 // also private can be accessed when really specified
    // s_interestRate = 5e10 was leaving wei out when calculating interest because of precision
    // 10^-8 == 1/ 10^8

    mapping(address => uint256) private s_userInterestRate; // KEEP TRACK on mint, of user interest rate
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);
    
    // deployer calls constructor so that will be the owner
    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) { // owneable could be different with admin roles
        
    }

    function grantBurnAndMintRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account); // this is centralized, known issue. The owner can grant mint and burn to anyone.
    }

    /**
     * @notice way of contract owner to set the interest rate
     * @param _newInterestRate The new interest rate to set
     * @dev the interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner { // onlyOwner can set interest rate
        if(_newInterestRate >= s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate ,_newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Mint the user tokens when they deposit into vault
     * @param _to the user to mint the tokens to
     * @param _amount the amount of tokens to mint
     */
    function mint(address _to, uint256 _amount, uint256 _userInterestRate) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = _userInterestRate; // fixed this to be dynamic because of vault
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the user tokens when they withdraw from vault
     * @param _from the user to burn the tokens from
     * @param _amount the amount of tokens to burn
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
    // burn for bridging to another token!!! also for when user redeeming or depositing
        
        // if(_amount == type(uint256).max) { // mititgate against DUST, leftover accrued tokens
        //     _amount = balanceOf(_from); // this is to actually redeem all balance of the user
        // } // removed because added to interface

        _mintAccruedInterest(_from);
        _burn(_from, _amount);
        
    }

    /**
     * @dev returns the principal balance of the user. The principal balance is the last
     * updated stored balance, which does not consider the perpetually accruing interest that has not yet been minted.
     * @param _user the address of the user
     * @return the principal balance of the user
     *
     */
    function principalBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Calculate the balance for the user including the interest that has accumulated since the last update
     * (principal balance) + some interest that has accrued
     * @param _user The address to calculate the balance of
     * @return balance of the user including interest
     */
    function balanceOf(address _user) public view override returns(uint256) {
        // get the current principal balance (number of tokens that have actually been minted) (mapping balances of ERC20)
        // multiyplye the principle balance by the interest rate that is accrued
        // s_interestRate runs per second meaning 0.000000005% is increasing in your balance per second!!!
    
        // balanceof and _calculate are both 1e18 so multiplication ends in 1e36, thats why we divide
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR; // this is cool to remmember, for better precision keep * and / together and clean
        // this is wrong, it has a compound interest that is not linear anymore as expected when user mints or burns. This is why this is a demo

        // the line above shows good example of using the super keyword
        // the function above, mint() is creating a different function so no super keyword 
    }

    /**
     * @notice found bug while doing tests but it later explains about the exploits of not having this function
     * @dev transfers tokens from the sender to the recipient. This function also mints any accrued interest since the last time the user's balance was updated.
     * @param _recipient the address of the recipient
     * @param _amount the amount of tokens to transfer
     * @return true if the transfer was successful
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        // accumulates the balance of the user so it is up to date with any interest accumulated.
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (balanceOf(_recipient) == 0) {
            // Update the users interest rate only if they have not yet got one (or they tranferred/burned all their tokens). Otherwise people could force others to have lower interest.
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

     /**
     * @dev transfers tokens from the sender to the recipient. This function also mints any accrued interest since the last time the user's balance was updated.
     * @param _sender the address of the sender
     * @param _recipient the address of the recipient
     * @param _amount the amount of tokens to transfer
     * @return true if the transfer was successful
     *
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }
        // accumulates the balance of the user so it is up to date with any interest accumulated.
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);
        if (balanceOf(_recipient) == 0) {
            // Update the users interest rate only if they have not yet got one (or they tranferred/burned all their tokens). Otherwise people could force others to have lower interest.
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice Calculate the interest that has accrued since the last update
     * @param _user The user to calculate the interest accumulated for
     * @return linearInterest interest that has accrued since the last update
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user) internal view returns(uint256 linearInterest) {
        // calculate the interest that has accrued since the last update
        // This is going to be linear growth with time
        // 1. calculate the time since the last update
        // 2. calculate the amount of linear growth
        // (principal amount) + (principal amount * user interest rate * time elapsed)
        // deposit: 10 tokens
        // interest rate 0.5 tokens per second
        // time elapsed: 2 seconds
        // 10 + (10 * 0.5 * 2)

        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        // principal amount(1 + (user interest rate * time elapsed) )
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed); // 18 decimal precision
    }

    /**
     * @notice Mint the accrued interest to the user since the last time they interacted with the protcol (eg. burn, mint, transfer)
     * @param _user The user to mint the accrued interest to
     */
    function _mintAccruedInterest(address _user) internal {
        // (1) find their current balance of the rebase tokens that have been minted to the user -> principal balance
        uint256 previousPrincipleBalance = super.balanceOf(_user);
        // (2) calculate their current balance including any interest -> balanceOf
        uint256 currentBalance = balanceOf(_user);
        // calculate the number of tokens that need to be minted to the -> user (2 actual balance of rebase token their are entitled to) - (1)
        uint256 balanceIncrease = currentBalance - previousPrincipleBalance;
        // set users latest update timestamp in accrued interest
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        // call _mint to mint the tokens to the user
        _mint(_user, balanceIncrease); // _mint EMITS an event already


        // this follow properly checks - effects (there isnt)- interactions
    }

    ///////////
    // view & pure functions
    ///////////

    /**
     * @dev returns the global interest rate of the token for future depositors
     * @return s_interestRate
     *
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @notice Get the interest rate of a user
     * @param _user The user to get the interest rate
     */
    function getUserInterestRate(address _user) external view returns(uint256) {
        return s_userInterestRate[_user];
    }
}

