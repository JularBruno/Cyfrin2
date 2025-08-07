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

/**
 * @title RebaseToken
 * @author jular
 * @notice This is a cross-chain rebase token that incentivises users to deposit into a vault and gain interest in rewards.
 * @notice The interest rate in the smart contract can only decrease 
 * @notice Each will user will have their own interest rate that is the global interest rate at the time of depositing.
*/
contract RebaseToken is ERC20 {
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private s_interestRate = 5e10; // 5% or 0.05 // also private can be accessed when really specified
    mapping(address => uint256) private s_userInterestRate; // KEEP TRACK on mint, of user interest rate
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);
    
    constructor() ERC20("Rebase Token", "RBT") {

    }

    /**
     * @notice way of contract owner to set the interest rate
     * @param _newInterestRate The new interest rate to set
     * @dev the interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external {
        if(_newInterestRate < s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate ,_newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * 
     */
    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);

    }

    function balanceOf(address _user) public view override returns(uint256) {
        // get the current principal balance (number of tokens that have actually been minted) (mapping balances of ERC20)
    }

    /**
     * 
     * @param _user 
     */
    function _mintAccruedInterest(address user) internal {
        // (1) find their current balance of the rebase tokens that have been minted to the user -> principal balance
        // (2) calculate their current balance including any interest -> balanceOf
        // calculate the number of tokens that need to be minted to the -> user (2 actual balance of rebase token their are entitled to) - (1)
        // call _mint to mint the tokens to the user
        // set users latest update timestamp in accrued interest

        s_userLastUpdatedTimestamp[_user] = block.timestamp;


    }

    ///////////
    // view & pure functions
    ///////////

    /**
     * @notice Get the interest rate of a user
     * @param _user The user to get the interest rate
     */
    function getUserInterestRate(address _user) external view returns(uint256) {
        return s_userInterestRate[_user];
    }
}

