// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// our invariants aka properties

// what are our invariants?

// 1. The total supply of DSC should be less than the total value of collateral
// 2. Getter view functions should never revert <- evergreen invariant

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import "forge-std/console2.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantsTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config;
    address weth;
    address wbtc;
    Handler handler;
    
    function setUp() external {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (,, weth, wbtc, ) = config.activeNetworkConfig();
        // targetContract(address(dsce)); // this goes wild
        handler = new Handler(dsce, dsc);
        targetContract(address(handler));

        // order tests, cant redeem if there isnt collateral
    }

    // this works only on fail_on_revert = false, it catches nothing. USELSS, ONLY FOR COURSE
    function invariant_protcolMustHaveMoreValueThanTotalSupply() public view {
        
        // get the value of all the collateral in the protcol
        // compare it to all the debt (dsc)
        uint256 totalSupply = dsc.totalSupply();
        uint256 totalWethDeposited = IERC20(weth).balanceOf(address(dsce));
        uint256 totalWbtcDeposited = IERC20(wbtc).balanceOf(address(dsce));

        uint256 wethValue = dsce.getUsdValue(weth, totalWethDeposited);
        uint256 wbtcValue = dsce.getUsdValue(wbtc, totalWbtcDeposited);

        assert(wethValue + wbtcValue >= totalSupply);
    }
    

}