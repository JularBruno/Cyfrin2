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
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    uint256 public constant AMOUNT_COLLATERAL_FOR_REDEEM = 1 ether;
    uint256 public constant AMOUNT_TO_MINT = 3 ether;
    uint256 public constant AMOUNT_TO_MINT_MORE_THAN_COLLATERAL = 8 ether;

    uint256 public constant LIQUIDATOR_COLLATERAL = 50 ether;

    uint256 public constant DSC_TO_MINT = 1000 ether;

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
    // redeem, burn, liquidate, depositCollateralAndMintDsc

    /////////////// 
    // Reedeming
    ///////////////
    // // test cant redeem 0

    // function testCantRedeemZero() public {}
    // function testCanredeemCollateral() public {}
    // function testCantRedeemMoreThanHelathFactorApproves() public {}
    // function testCanredeemCollateralForDsc() public {}

    // function testCanBurnDsc() public {}
    // function testCanLiquidate() public {}

    function testCantRedeemZero() public depositCollateral {
        vm.startPrank(USER);
        
        // Try to redeem zero - should revert
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        dsce.redeemCollateral(weth, 0);
        
        vm.stopPrank();
    }

    function testCanRedeemCollateral() public depositCollateral {
        vm.startPrank(USER);
        
        uint256 initialBalance = ERC20Mock(weth).balanceOf(USER);
        uint256 amountToRedeem = 5 ether;
        
        // Redeem part of collateral
        dsce.redeemCollateral(weth, amountToRedeem);
        
        // Check balance increased
        uint256 finalBalance = ERC20Mock(weth).balanceOf(USER);
        assertEq(finalBalance, initialBalance + amountToRedeem);
        
        // Check collateral was reduced in contract
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
        assertEq(totalDscMinted, 0);

        // Should have 5 ether worth of collateral left (5 * 2000 = 10000)
        assertEq(collateralValueInUsd, 10000e18);
        
        vm.stopPrank();
    }

    function testCantRedeemMoreThanHealthFactorAllows() public depositCollateral {
        vm.startPrank(USER);

        dsce.mintDsc(DSC_TO_MINT); // Setup: Mint DSC against deposited collateral

        uint256 tooMuchToRedeem = 9.5 ether; 
        // Calculate expected health factor after redemption
        // Remaining collateral: 0.5 ETH × $2000 = $1000
        // Adjusted collateral: $1000 × 50 / 100 = $500
        // Health factor: $500 / $100 = 5e17 (0.5)
        uint256 expectedHealthFactor = 5e17;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__BreaksHealthFactor.selector,
                expectedHealthFactor
            )
        );
        // Try to redeem too much - this should leave insufficient collateral
        dsce.redeemCollateral(weth, tooMuchToRedeem); // Leave only 0.5 ETH ($1000)
        
        vm.stopPrank();
    }

    function testCanredeemCollateralForDsc() public {
        vm.startPrank(USER);
        
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT);

        uint256 initialDscBalance = dsc.balanceOf(USER);

        // Approve DSC to be burned and Redeem collateral for DSC
        dsc.approve(address(dsce), AMOUNT_TO_MINT);
        dsce.redeemCollateralForDsc(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT);   
        
        vm.stopPrank();

        uint256 finalUserBalance = dsc.balanceOf(USER);
        assertEq(initialDscBalance, 3 ether);
        assertEq(finalUserBalance, 0);
    }


    /////////////// 
    // Liquidation
    ///////////////

    function testCanLiquidate() public {
        // Setup user with collateral and DSC
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollateralAndMintDsc(weth, AMOUNT_COLLATERAL, AMOUNT_TO_MINT);
        vm.stopPrank();
        
        // Crash the price to make user undercollateralized
        MockV3Aggregator(ethUsdPriceFeed).updateAnswer(5e7); // ETH price drops to $0.50
        
        // Setup liquidator - GIVE THEM WETH FIRST
        vm.startPrank(LIQUIDATOR);

        ERC20Mock(weth).mint(LIQUIDATOR, LIQUIDATOR_COLLATERAL); // ← This gives them WETH
        ERC20Mock(weth).approve(address(dsce), LIQUIDATOR_COLLATERAL);
        dsce.depositCollateralAndMintDsc(weth, LIQUIDATOR_COLLATERAL, AMOUNT_TO_MINT);
        
        // Liquidate the user
        uint256 debtToCover = 1 ether; // Cover part of user's debt
        dsc.approve(address(dsce), debtToCover);
        
        uint256 liquidatorInitialWethBalance = ERC20Mock(weth).balanceOf(LIQUIDATOR);
        
        dsce.liquidate(weth, USER, debtToCover);
        
        // Check liquidator received bonus collateral
        uint256 liquidatorFinalWethBalance = ERC20Mock(weth).balanceOf(LIQUIDATOR);
        assert(liquidatorFinalWethBalance > liquidatorInitialWethBalance);
        
        vm.stopPrank();
    }

}