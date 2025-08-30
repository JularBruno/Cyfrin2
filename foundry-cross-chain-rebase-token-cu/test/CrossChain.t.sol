// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";

import { RebaseToken } from "../src/RebaseToken.sol";
import { RebaseTokenPool } from "../src/RebaseTokenPool.sol";
import { Vault } from "../src/Vault.sol";

import { IRebaseToken } from "../src/interfaces/IRebaseToken.sol";

import { CCIPLocalSimulatorFork, Register } from '@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol';

// remmember IERC20 from ccip is not the same one as chinlink contract for IERC20
import { IERC20 } from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol"; // not the same interface from the token pool as IERC20 from oppenezeppelin
import { RegistryModuleOwnerCustom } from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import { TokenAdminRegistry } from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

contract CrossChainTest is Test {

    address owner = makeAddr("owner"); // cant be constant!
    
    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    CCIPLocalSimulatorFork ccipLocalSimulatorFork;

    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;

    Vault vault;

    RebaseTokenPool sepoliaPool;
    RebaseTokenPool arbSepoliaPool;

    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbSepoliaNetworkDetails;
    
    function setUp() public {
        sepoliaFork = vm.createSelectFork("sepolia");

        arbSepoliaFork = vm.createFork("arb-sepolia");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork)); // makes address persistent on both chains

        // 1. Deploy and configure on Sepolia
        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        
        vm.startPrank(owner);

        sepoliaToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        sepoliaPool = 
            new RebaseTokenPool(IERC20(address(sepoliaToken)), 
            new address[](0), 
            sepoliaNetworkDetails.rmnProxyAddress, 
            sepoliaNetworkDetails.routerAddress
        );

        sepoliaToken.grantBurnAndMintRole(address(vault)); // could explain in every step what it does but is very specific, like here granting permission to vault, readme has docs if this confusing.abi
        sepoliaToken.grantBurnAndMintRole(address(sepoliaPool));
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress)
            .registerAdminViaOwner(address(sepoliaToken));
        
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(address(sepoliaToken), address(sepoliaPool));

        vm.stopPrank();

        // 2. Deploy and configure on Arbitrum Sepolia
        vm.selectFork(arbSepoliaFork);

        vm.startPrank(owner);

        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);
        
        arbSepoliaToken = new RebaseToken();
        arbSepoliaPool = 
            new RebaseTokenPool(IERC20(address(arbSepoliaToken)), 
            new address[](0), 
            arbSepoliaNetworkDetails.rmnProxyAddress, 
            arbSepoliaNetworkDetails.routerAddress
        );

        sepoliaToken.grantBurnAndMintRole(address(arbSepoliaPool));
        // again check docs, this step 4 on chainlink ccip register-from-eoa-burn-mint-foundry
        RegistryModuleOwnerCustom(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(arbSepoliaToken)); 
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(address(arbSepoliaToken), address(arbSepoliaToken));

        vm.stopPrank();
    }


}