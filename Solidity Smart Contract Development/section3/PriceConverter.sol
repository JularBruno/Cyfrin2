// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol"; // interfaces are for interact with ABI contract without actual functions in it


library PriceConverter {
    
    function getPrice() internal view returns (uint256){
        // Address 0x694AA1769357215DE4FAC081bf1f309aDC325306 // eth usd sepolia
        // ABI list of functions of a contract
        // bboth things are required for this 

        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        // prettier-ignore
        (, int256 answer, , , )  = priceFeed.latestRoundData(); // int because values can be negative
        // uint80 roundID, ,uint startedAt ,uint timeStamp ,uint80 answeredInRound

        return uint256(answer * 1e10); // decimal places from eth to usd, and also from int to uint
    }

    function getConversionRate(uint256 ethAmount) internal view returns (uint256) {
        // 1 ETH?
        // 2000_0000000000000000000
        uint256 ethPrice = getPrice();
        // 1 / 2 = 0
        // 2000_0000000000000000000 * 1_000000000000000000) / 1e18
        // $2000 = 1 ETH
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}