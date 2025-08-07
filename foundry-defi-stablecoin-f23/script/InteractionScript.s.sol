// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol"; 
import {DeployDSC} from "./DeployDSC.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";

contract InteractionsScript is Script {
    
    DecentralizedStableCoin dsc;
    DSCEngine dsce;
    HelperConfig config;
    
    address weth;
    address wbtc;
    uint256 deployerKey;
    
    function setUp() public {
        DeployDSC deployer = new DeployDSC();
        (dsc, dsce, config) = deployer.run();
        
        (,, weth, wbtc, deployerKey) = config.activeNetworkConfig();
    }
    
    function run() external {
        setUp();
        
        // Example interaction sequence
        dsce.depositCollateralAndMintDsc();
        dsce.checkHealthFactor();
        dsce.redeemCollateral();
    }
}

// Script to deposit collateral and mint DSC
contract DepositAndMint is Script {
    
    function run() external {
        // Get deployed contracts
        DeployDSC deployer = new DeployDSC();
        (DecentralizedStableCoin dsc, DSCEngine engine, HelperConfig config) = deployer.run();
        
        (,, address weth, address wbtc, uint256 deployerKey) = config.activeNetworkConfig();
        
        uint256 collateralAmount = 10 ether; // 10 WETH
        uint256 dscToMint = 5000 ether; // 5000 DSC (assuming 50% collateralization)
        
        vm.startBroadcast(deployerKey);
        
        // First, mint some WETH to the user (for Anvil testing)
        ERC20Mock(weth).mint(msg.sender, collateralAmount);
        
        // Approve the engine to spend WETH
        ERC20Mock(weth).approve(address(engine), collateralAmount);
        
        console.log("Depositing", collateralAmount, "WETH as collateral");
        console.log("Minting", dscToMint, "DSC");
        
        // Deposit collateral and mint DSC in one transaction
        engine.depositCollateralAndMintDsc(weth, collateralAmount, dscToMint);
        
        vm.stopBroadcast();
        
        // Check balances
        console.log("DSC Balance:", dsc.balanceOf(msg.sender));
        console.log("Collateral Deposited:", engine.getCollateralBalanceOfUser(msg.sender, weth));
    }
}

// // Script to just deposit collateral
// contract DepositCollateral is Script {
    
//     function run() external {
//         DeployDSC deployer = new DeployDSC();
//         (DecentralizedStableCoin dsc, DSCEngine engine, HelperConfig config) = deployer.run();
        
//         (,, address weth,, uint256 deployerKey) = config.activeNetworkConfig();
        
//         uint256 collateralAmount = 5 ether;
        
//         vm.startBroadcast(deployerKey);
        
//         // Mint WETH for testing
//         ERC20Mock(weth).mint(msg.sender, collateralAmount);
//         ERC20Mock(weth).approve(address(engine), collateralAmount);
        
//         console.log("Depositing", collateralAmount, "WETH as collateral");
//         engine.depositCollateral(weth, collateralAmount);
        
//         vm.stopBroadcast();
        
//         console.log("Collateral Deposited:", engine.getCollateralBalanceOfUser(msg.sender, weth));
//     }
// }

// // Script to mint DSC (requires existing collateral)
// contract MintDsc is Script {
    
//     function run() external {
//         DeployDSC deployer = new DeployDSC();
//         (DecentralizedStableCoin dsc, DSCEngine engine, HelperConfig config) = deployer.run();
        
//         (, uint256 deployerKey) = config.activeNetworkConfig();
        
//         uint256 dscToMint = 1000 ether; // 1000 DSC
        
//         vm.startBroadcast(deployerKey);
        
//         console.log("Minting", dscToMint, "DSC");
//         engine.mintDsc(dscToMint);
        
//         vm.stopBroadcast();
        
//         console.log("DSC Balance:", dsc.balanceOf(msg.sender));
//     }
// }

// // Script to burn DSC and redeem collateral
// contract BurnAndRedeem is Script {
    
//     function run() external {
//         DeployDSC deployer = new DeployDSC();
//         (DecentralizedStableCoin dsc, DSCEngine engine, HelperConfig config) = deployer.run();
        
//         (,, address weth,, uint256 deployerKey) = config.activeNetworkConfig();
        
//         uint256 dscToBurn = 1000 ether;
//         uint256 collateralToRedeem = 1 ether;
        
//         vm.startBroadcast(deployerKey);
        
//         // Approve engine to burn DSC
//         dsc.approve(address(engine), dscToBurn);
        
//         console.log("Burning", dscToBurn, "DSC and redeeming", collateralToRedeem, "WETH");
//         engine.redeemCollateralForDsc(weth, collateralToRedeem, dscToBurn);
        
//         vm.stopBroadcast();
        
//         console.log("Remaining DSC Balance:", dsc.balanceOf(msg.sender));
//         console.log("Remaining Collateral:", engine.getCollateralBalanceOfUser(msg.sender, weth));
//     }
// }

// // Script to check account information
// contract CheckAccountInfo is Script {
    
//     function run() external view {
//         DeployDSC deployer = new DeployDSC();
//         (DecentralizedStableCoin dsc, DSCEngine engine, HelperConfig config) = deployer.run();
        
//         address user = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Default Anvil address
        
//         console.log("=== Account Information ===");
//         console.log("User Address:", user);
//         console.log("DSC Balance:", dsc.balanceOf(user));
        
//         (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(user);
//         console.log("Total DSC Minted:", totalDscMinted);
//         console.log("Collateral Value (USD):", collateralValueInUsd);
        
//         uint256 healthFactor = engine.getHealthFactor(user);
//         console.log("Health Factor:", healthFactor);
        
//         if (healthFactor < 1e18) {
//             console.log("WARNING: Account is undercollateralized!");
//         } else {
//             console.log("Account is healthy");
//         }
//     }
// }

// // Script to simulate liquidation scenario
// contract TestLiquidation is Script {
    
//     function run() external {
//         DeployDSC deployer = new DeployDSC();
//         (DecentralizedStableCoin dsc, DSCEngine engine, HelperConfig config) = deployer.run();
        
//         (address wethPriceFeed,, address weth,, uint256 deployerKey) = config.activeNetworkConfig();
        
//         vm.startBroadcast(deployerKey);
        
//         // First, set up a position
//         uint256 collateralAmount = 10 ether;
//         uint256 dscToMint = 15000 ether; // High leverage for testing
        
//         ERC20Mock(weth).mint(msg.sender, collateralAmount);
//         ERC20Mock(weth).approve(address(engine), collateralAmount);
        
//         engine.depositCollateralAndMintDsc(weth, collateralAmount, dscToMint);
        
//         console.log("Initial Health Factor:", engine.getHealthFactor(msg.sender));
        
//         vm.stopBroadcast();
        
//         // Now simulate price crash (this would be done by the mock aggregator owner)
//         console.log("Simulate ETH price crash to trigger liquidation...");
//         console.log("You can update the price using MockV3Aggregator.updateAnswer()");
//     }
// }

// // Helper script to update mock price feeds (useful for testing liquidations)
// contract UpdatePrices is Script {
    
//     function run() external {
//         DeployDSC deployer = new DeployDSC();
//         (, DSCEngine engine, HelperConfig config) = deployer.run();
        
//         (address wethPriceFeed,, address weth,, uint256 deployerKey) = config.activeNetworkConfig();
        
//         // New price: $1000 (50% crash from $2000)
//         int256 newPrice = 1000e8;
        
//         vm.startBroadcast(deployerKey);
        
//         // Update the mock price feed
//         (bool success,) = wethPriceFeed.call(
//             abi.encodeWithSignature("updateAnswer(int256)", newPrice)
//         );
//         require(success, "Price update failed");
        
//         vm.stopBroadcast();
        
//         console.log("Updated WETH price to:", uint256(newPrice));
        
//         // Check if any accounts are now liquidatable
//         address testUser = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
//         uint256 healthFactor = engine.getHealthFactor(testUser);
//         console.log("User health factor after price update:", healthFactor);
//     }
// }