// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {RebaseToken} from "../src/RebaseToken.sol";
import {RebaseTokenPool} from "../src/RebaseTokenPool.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interfaces/IRebaseToken.sol";

import {Test, console} from "forge-std/Test.sol";

import {CCIPLocalSimulatorFork, Register} from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import {RegistryModuleOwnerCustom} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import {TokenAdminRegistry} from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";
import {TokenPool} from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import {RateLimiter} from "@ccip/contracts/src/v0.8/ccip/libraries/RateLimiter.sol";
import {Client} from "@ccip/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@ccip/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
// remmember IERC20 from ccip is not the same one as chinlink contract for IERC20
import {IERC20} from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol"; // not the same interface from the token pool as IERC20 from oppenezeppelin

contract CrossChainTest is Test {
    address public owner = makeAddr("owner"); // cant be constant!
    address user = makeAddr("user"); // cant be constant!
    uint256 SEND_VALUE = 1e5;

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
        address[] memory allowlist = new address[](0);

        sepoliaFork = vm.createSelectFork("sepolia");

        arbSepoliaFork = vm.createFork("arb-sepolia");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork)); // makes address persistent on both chains

        // 1. Deploy and configure on Sepolia
        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        vm.startPrank(owner);

        sepoliaToken = new RebaseToken();

        console.log("source rebase token address");
        console.log(address(sepoliaToken));
        console.log("Deploying token pool on Sepolia");

        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        sepoliaPool = new RebaseTokenPool(
            IERC20(address(sepoliaToken)),
            allowlist,
            sepoliaNetworkDetails.rmnProxyAddress,
            sepoliaNetworkDetails.routerAddress
        );

        sepoliaToken.grantBurnAndMintRole(address(vault)); // could explain in every step what it does but is very specific, like here granting permission to vault, readme has docs if this confusing.abi
        sepoliaToken.grantBurnAndMintRole(address(sepoliaPool));
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(sepoliaToken)
        );

        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(sepoliaToken), address(sepoliaPool)
        );

        vm.stopPrank();

        // 2. Deploy and configure on Arbitrum Sepolia
        vm.selectFork(arbSepoliaFork);

        vm.startPrank(owner);

        console.log("Deploying token on Arbitrum");

        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainid);

        arbSepoliaToken = new RebaseToken();

        console.log("dest rebase token address");
        console.log(address(arbSepoliaToken));
        

        arbSepoliaPool = new RebaseTokenPool(
            IERC20(address(arbSepoliaToken)),
            allowlist,
            arbSepoliaNetworkDetails.rmnProxyAddress,
            arbSepoliaNetworkDetails.routerAddress
        );

        console.log('before token admin registry'); // this was for catching a setup bug
//         console.log("Token address:", address(arbSepoliaToken)); // ARB token, not sepolia
//         console.log("RNM Proxy:", arbSepoliaNetworkDetails.rmnProxyAddress); // ARB details
//         console.log("Router:", arbSepoliaNetworkDetails.routerAddress); // ARB details

        arbSepoliaToken.grantBurnAndMintRole(address(arbSepoliaPool));
        // again check docs, this step 4 on chainlink ccip register-from-eoa-burn-mint-foundry
        RegistryModuleOwnerCustom(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(
            address(arbSepoliaToken)
        );

        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(
            address(arbSepoliaToken), address(arbSepoliaPool)
        );
        
        vm.stopPrank();

        // before stoping prank and after configuring pools
        configureTokenPool(
            sepoliaFork,
            address(sepoliaPool),
            arbSepoliaNetworkDetails.chainSelector,
            address(arbSepoliaPool),
            address(arbSepoliaToken)
        );
        configureTokenPool(
            arbSepoliaFork,
            address(arbSepoliaPool),
            sepoliaNetworkDetails.chainSelector,
            address(sepoliaPool),
            address(sepoliaToken)
        );

    }

    // local and remote selection
    function configureTokenPool(
        uint256 fork,
        address localPool,
        uint64 remoteChainSelector,
        address remotePool,
        address remoteTokenAddress
    ) public {
        vm.selectFork(fork);

        // bytes[] memory remotePoolAddresses = new bytes[](1); // this was from course review if update really worked
        // remotePoolAddresses[0] = abi.encode(remotePool);
        vm.startPrank(owner);
        TokenPool.ChainUpdate[] memory chainsToAdd = new TokenPool.ChainUpdate[](1);

        // struct ChainUpdate {
        //     uint64 remoteChainSelector; // ──╮ Remote chain selector
        //     bool allowed; // ────────────────╯ Whether the chain should be enabled
        //     bytes remotePoolAddress; //        Address of the remote pool, ABI encoded in the case of a remote EVM chain.
        //     bytes remoteTokenAddress; //       Address of the remote token, ABI encoded in the case of a remote EVM chain.
        //     RateLimiter.Config outboundRateLimiterConfig; // Outbound rate limited config, meaning the rate limits for all of the onRamps for the given chain
        //     RateLimiter.Config inboundRateLimiterConfig; // Inbound rate limited config, meaning the rate limits for all of the offRamps for the given chain
        // };

        chainsToAdd[0] = TokenPool.ChainUpdate({
            remoteChainSelector: remoteChainSelector,
            allowed: true,
            remotePoolAddress: abi.encode(remotePool),
            remoteTokenAddress: abi.encode(remoteTokenAddress),
            outboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0}),
            inboundRateLimiterConfig: RateLimiter.Config({isEnabled: false, capacity: 0, rate: 0})
        });

        // TokenPool(localPool).applyChainUpdates(new uint64[](0), chainsToAdd);
        // vm.prank(owner);
        TokenPool(localPool).applyChainUpdates(chainsToAdd);
        vm.stopPrank();

    }

    function bridgeTokens(
        uint256 amountToBridge, uint256 localFork, uint256 remoteFork, 
        Register.NetworkDetails memory localNetworkDetails, Register.NetworkDetails memory remoteNetworkDetails, 
        RebaseToken localToken, RebaseToken remoteToken) 
    public {
        vm.selectFork(localFork);
        // vm.startPrank(user);

        //   struct EVM2AnyMessage {
        //     bytes receiver; // abi.encode(receiver address) for dest EVM chains
        //     bytes data; // Data payload
        //     EVMTokenAmount[] tokenAmounts; // Token transfers
        //     address feeToken; // Address of feeToken. address(0) means you will send msg.value.
        //     bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV2)
        //   }
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: address(localToken),
            amount: amountToBridge
        });

        IERC20 linkToken = IERC20(localNetworkDetails.linkAddress);
        uint256 linkBalance = linkToken.balanceOf(address(this));
        console.log("LINK balance:", linkBalance);

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(user),
            data: "",
            tokenAmounts: tokenAmounts,
            feeToken: localNetworkDetails.linkAddress, // we want this to be link tokens
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV2({gasLimit: 500_000, allowOutOfOrderExecution: false})) // have to pass custom gas limit for testing actually should be 0 // we don't want a custom gasLimit // read docs because there is EVMExtraArgsV1 and EVMExtraArgsV2
        });
        
        
        uint256 fee = IRouterClient(localNetworkDetails.routerAddress).getFee(remoteNetworkDetails.chainSelector, message); // in order to use routerAddress contract we need to cast it
        ccipLocalSimulatorFork.requestLinkFromFaucet(user, fee); // vm deal cheatcode!!! this why we required single lined pranks
        vm.prank(user);
        IERC20(localNetworkDetails.linkAddress).approve(localNetworkDetails.routerAddress, fee);
        
        vm.prank(user);
        IERC20(address(localToken)).approve(localNetworkDetails.routerAddress, amountToBridge); // router address can approve local token
        // 
        uint256 localBalanceBefore = localToken.balanceOf(user);
        //
        vm.prank(user);
        IRouterClient(localNetworkDetails.routerAddress).ccipSend(remoteNetworkDetails.chainSelector, message);
        //
        uint256 localBalanceAfter = localToken.balanceOf(user);
        assertEq(localBalanceAfter, localBalanceBefore - amountToBridge);
        uint256 localUserInterestRate = localToken.getUserInterestRate(user);
        //
        // vm.stopPrank();
        //
        vm.selectFork(remoteFork);
        vm.warp(block.timestamp + 20 minutes); // warp timestamp because it takes time to propagate

        
        // get initial balance on Arbitrum
        // uint256 initialArbBalance = IERC20(address(remoteToken)).balanceOf(alice);
        // console.log("Remote balance before bridge: %d", initialArbBalance);
        // vm.selectFork(localFork); // in the latest version of chainlink-local, it assumes you are currently on the local fork before calling switchChainAndRouteMessage
        // ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteFork);

        // console.log("Remote user interest rate: %d", remoteToken.getUserInterestRate(alice));
        // uint256 destBalance = IERC20(address(remoteToken)).balanceOf(alice);
        // console.log("Remote balance after bridge: %d", destBalance);
        // assertEq(destBalance, initialArbBalance + amountToBridge);

        uint256 remoteBalanceBefore = IERC20(address(remoteToken)).balanceOf(user);
        console.log("Remote balance before bridge: %d", remoteBalanceBefore);


        vm.selectFork(localFork); // in the latest version of chainlink-local, it assumes you are currently on the local fork before calling switchChainAndRouteMessage
        ccipLocalSimulatorFork.switchChainAndRouteMessage(remoteFork); // we could select fork or do this THERE is an error here

        console.log('does this reach');
        console.log("Remote user interest rate: %d", remoteToken.getUserInterestRate(user));


        uint256 remoteBalanceAfter = IERC20(address(remoteToken)).balanceOf(user);
        console.log("Remote balance after bridge: %d", remoteBalanceAfter);

        uint256 expectedBalance = remoteBalanceBefore + amountToBridge; // this because "stack too deep" error
        assertEq(remoteBalanceAfter, expectedBalance);
        console.log('AHHHHHHHHH');

        // uint256 remoteUserInterestRate = localToken.getUserInterestRate(user);
        // assertEq(localUserInterestRate, remoteUserInterestRate);
        // assert interest rates
        //
    }

    function testBridgeAllTokens() public {
        vm.selectFork(sepoliaFork);
        vm.deal(user, SEND_VALUE);
        
        vm.prank(user);
        Vault(payable(address(vault))).deposit{value: SEND_VALUE}(); // THIS GREAT line that has many concepts, first we want to deposit with an amount so we send value on the curly braces. then for the address of the vault, payable, we call the Vault for making a deposit

        assertEq(sepoliaToken.balanceOf(user), SEND_VALUE); // balance of takes time irl

        bridgeTokens(SEND_VALUE, sepoliaFork, arbSepoliaFork, sepoliaNetworkDetails, arbSepoliaNetworkDetails, sepoliaToken, arbSepoliaToken);
    }
}
