// Get funds from users
// withdraw funds
// set a minimum funding value in usd

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; // interfaces are for interact with ABI contract without actual functions in it

import {PriceConverter} from "./PriceConverter.sol";


error NotOwner();


contract FundMe {

    using PriceConverter for uint256; // FOR LIBRARY PriceConverter, since it can be called directly on uint256

    // uint256 public myValue = 1; // this is used to explain revert
    // uint256 public minimumUsd = 5e18;
    uint256 public constant MINIMUM_USD = 5e18; // CONSTANT REDUCES GAS A LOT
    address[] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded; // map senders and the sent value

    address public immutable i_owner; // immutable REDUCES GAS A LOT is inside the byte code of the contract
    constructor() { // regular constructor, called on deploy
        i_owner = msg.sender; // withdraw available only for the owner
    }

    function fund() public payable{
        // allow to send $
        // have a minimum amount

        // this is cool for explaining over each transaction FIELDS, with its VALUE TRANSFERS (gas, to, data), FUNCTION CALL (can specify wei in fields)
        // what is a revert? undo any transaction done bacuase next one failed, and send remainging gas back
        // myValue = myValue +2; 

        // how to send eth to this contract?
        // require(msg.value >= minimumUsd, "didn't send enough eth"); // 1e18 = 1 eth = 1 * 10 ** 18 = valuew in wei (** means raised)
        
        // require(getConversionRate(msg.value) >= minimumUsd, "didn't send enough eth"); // require is kind of trycatch

        // here is the version where a library is used. Can have parameters but msg.value will be always the first parameter
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't send enough eth"); 

        // https breaks conscensus
        // with chainlink networks because of oracle problem

        // msg.value 18 decimal places because of Wei

        funders.push(msg.sender); // another global variable that can be called in solidity for getting the sender, can be seen in docs
        // addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {

        // require(msg.sender == owner, "Must be owner!");

        // 
        /* starting index, ending index, step amount */
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++ ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0); // RESET the array

        // // actually withdraw funds

        // // transfer send and all are the three ways
        // msg.sender = address
        // payable(msg.sender) = payable address
        // https://solidity-by-example.org/sending-ether/

        // payable(msg.sender).transfer(address(this).balance); // transfer all balance in the contract

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        // // call lower level command first one used, doesnt require ABI

        // bytes need to be memory because of array
        // dataReturned not required since we not calling function
        // (bool callSuccess, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}(""); // use as transaction
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}(""); // use as transaction
        require(callSuccess, "Call failed");


        
    }

    // modifier creates ability to create keyword to put right in any function declaration
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Must be owner!");
        if (msg.sender != i_owner) { // GAS eficient, both might appear check for solidity new thigns if require or sth
            revert NotOwner();
        }
        _;
    }


    // what happens if someone sends money without calling fund()
    // receive () or fallback()

    receive() external payable {
        fund();
    }
    
    fallback() external payable {
        fund();
    }
}
