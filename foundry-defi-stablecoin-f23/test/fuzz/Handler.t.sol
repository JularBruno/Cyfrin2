// handler will narrow down the way we call a function and will replace dsce in invariants tests

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";

import {StdInvariant} from "forge-std/StdInvariant.sol";
import "forge-std/console2.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

// price feed, weth token, wbtc token are contracts that can also be handled

contract Handler is Test {
    
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 public timesMintIsCalled;
    address[] public usersWithCollateralDeposited;
    MockV3Aggregator public ethUsdPriceFeed;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;
    
    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);

        ethUsdPriceFeed = MockV3Aggregator(dsce.getCollateralTokenPriceFeed(address(weth)));
    }

    function mintDsc(uint256 amount, uint256 addressSeed) public {
        // this was not reaching mint
        // msg.sender does not necessarly meant that the user deposited collateral, meaning cannot mint (there could be a bug as well)
        if(usersWithCollateralDeposited.length == 0) { return; }
        address sender = usersWithCollateralDeposited[addressSeed % usersWithCollateralDeposited.length]; 

        (uint256 totalDscMinted, uint256 collateralValueInUsd) = 
        // dsce.getAccountInformation(msg.sender); // this is left for explaining the not reaching mint
        dsce.getAccountInformation(sender);
        
        // console2.log("totalDscMinted ", totalDscMinted);
        // console2.log("collateralValueInUsd ", collateralValueInUsd);
        int256 maxDscToMint = (int256(collateralValueInUsd) / 2) - int256(totalDscMinted);
        // console2.log("maxDscToMint ", maxDscToMint);

        if(maxDscToMint == 0) { return; }
        
        amount = bound(amount, 0, uint256(maxDscToMint));
        
        if(amount == 0) { return; }
        
        vm.startPrank(sender);
        dsce.mintDsc(amount);
        vm.stopPrank();
        timesMintIsCalled++;
    }

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        // this adds some guardrails!
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed); 
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender); //whoever calls this function has some collateral that why ERC20Mock is being used

        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);

        dsce.depositCollateral(address(collateral), amountCollateral); 
        vm.stopPrank();
        // there might be double push, check 
        usersWithCollateralDeposited.push(msg.sender);
    }

    function redeemCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed);

        // redeem obviiously the max amount sender has on the system
        uint256 maxCollateralToRedeem = dsce.getCollateralBalanceOfUser(address(collateral), msg.sender);

        amountCollateral = bound(amountCollateral, 0, maxCollateralToRedeem); // if user is requiring more? fail on revert or not fail on revert
        if (amountCollateral == 0) {
            return; // THIS doesnt call function when fuzz
        }

        dsce.redeemCollateral(address(collateral), amountCollateral);
    }

    // This breaks our invariant test suite
    // calldata=updateCollateralPrice(uint96) args=[2499]
    // function updateCollateralPrice(uint96 newPrice) public {
    //     int256 newPriceInt = int256(uint256(newPrice));
    //     ethUsdPriceFeed.updateAnswer(newPriceInt);

    // }


    // helper functions
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock seed) 
    {
        if(collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}

