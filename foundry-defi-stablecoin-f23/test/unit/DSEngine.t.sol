// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
// import {Test, console} from "forge-std/Test.sol";
import "forge-std/console2.sol";

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;

    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    uint256 public constant AMOUNT_COLLATERAL_FOR_REDEEM = 1 ether;
    uint256 public constant AMOUNT_TO_MINT = 3 ether;
    uint256 public constant AMOUNT_TO_MINT_MORE_THAN_COLLATERAL = 8 ether;
    
    function setUp() public {
        deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, ,) = config.activeNetworkConfig();

        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    /////////////// 
    // Constructor tests
    ///////////////

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);

        vm.expectRevert(DSCEngine.DSCEngine__TokenAdressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }


    /////////////// 
    // Price tests
    ///////////////

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18; // 15 eth so 15e18 * 2000/ETH = 30.000e18

        uint256 expectedUsd = 30000e18; // this wont work in sepolia TODO update to be more agnostic
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);

        assertEq(actualUsd, expectedUsd);
    }

    function testGetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = dsce.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(actualWeth, expectedWeth);
    }

    /////////////// 
    // Deposit collateral tests
    ///////////////

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);

        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);

        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.depositCollateral(weth, 0);

        vm.stopPrank();

    }
    
    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector); 
        dsce.depositCollateral(address(ranToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    // we might need reentrancy tests

    modifier depositCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL); // user gives contract permission to tranfer AMOUNT_COLLATERAL worth of weth on their behalf
        dsce.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
        
        uint256 expectedTotalDscMinted = 0;
        uint256 expectedDepositAmount = dsce.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, expectedTotalDscMinted);
        assertEq(AMOUNT_COLLATERAL, expectedDepositAmount);
    }

    /////////////// 
    // My tests, I think the first ones should be about MINTING
    ///////////////
    // i think the bug on the course is about being able to redeem collateral based on the health factor calculation

    // function testCanMintDscAfterCollateralDeposit() public depositCollateral {
    function testCanMintDscAfterCollateralDepositAndHealthFactorRetrievesTheCorrectValue() public depositCollateral {

        vm.startPrank(USER);
        dsce.mintDsc(AMOUNT_TO_MINT);
        vm.stopPrank();

        (uint256 totalDscMinted, ) = dsce.getAccountInformation(USER);
        assertEq(totalDscMinted, AMOUNT_TO_MINT);

        uint256 userHealthFactor = dsce.getHealthFactor(USER);
        assert(userHealthFactor > dsce.minHealthFactor());
    }

    function testCantMintMoreDscThanCollateralAvialable() public depositCollateral {

        uint256 usdCollateralValue = dsce.getUsdValue(weth, AMOUNT_COLLATERAL);
        uint256 maxSafeMint = (usdCollateralValue * dsce.getLiquidationThreshold()) / dsce.getLiquidationPrecision(); 
        uint256 mintForExpectedRevert = maxSafeMint + 1;

        vm.startPrank(USER);
        vm.expectRevert();
        dsce.mintDsc(mintForExpectedRevert);

        vm.stopPrank();

        // assert(userHealthFactor > dsce.minHealthFactor());
    }

    // TODO 80% COVERAGE

    /////////////// 
    // Reedeming
    ///////////////
    // // test cant redeem 0
    // function testCanDepositCollateralAndThenRedeem() public depositCollateral {
    //     uint256 userWethBalanceBefore = ERC20Mock(weth).balanceOf(USER);

    //     vm.startPrank(USER);
    //     dsce.redeemCollateral(weth, AMOUNT_COLLATERAL_FOR_REDEEM);
    //     vm.stopPrank();

    //     console.log('userWethBalanceBefore ', userWethBalanceBefore);
    //     uint256 userWethBalanceAfter = ERC20Mock(weth).balanceOf(USER);
    //     console.log('userWethBalanceAfter ', userWethBalanceAfter);

    //     assertEq(userWethBalanceAfter, userWethBalanceBefore - AMOUNT_COLLATERAL_FOR_REDEEM);

    //     // (, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
    //     // assertEq(collateralValueInUsd, 0);
    // }

}