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

contract Handler is Test {
    
    DSCEngine dsce;
    DecentralizedStableCoin dsc;

    ERC20Mock weth;
    ERC20Mock wbtc;

    uint256 MAX_DEPOSIT_SIZE = type(uint96).max;
    
    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) {
        dsce = _dscEngine;
        dsc = _dsc;

        address[] memory collateralTokens = dsce.getCollateralTokens();
        weth = ERC20Mock(collateralTokens[0]);
        wbtc = ERC20Mock(collateralTokens[1]);
    }

    // redeem collateral

    function depositCollateral(uint256 collateralSeed, uint256 amountCollateral) public {
        // this adds some guardrails!
        ERC20Mock collateral = _getCollateralFromSeed(collateralSeed); 
        amountCollateral = bound(amountCollateral, 1, MAX_DEPOSIT_SIZE);

        vm.startPrank(msg.sender); //whoever calls this function has some collateral that why ERC20Mock is being used

        collateral.mint(msg.sender, amountCollateral);
        collateral.approve(address(dsce), amountCollateral);

        dsce.depositCollateral(address(collateral), amountCollateral); 
        vm.stopPrank();

    }


    // helper functions
    function _getCollateralFromSeed(uint256 collateralSeed) private view returns (ERC20Mock seed) 
    {
        if(collateralSeed % 2 == 0) {
            return weth;
        }
        return wbtc;
    }
}

