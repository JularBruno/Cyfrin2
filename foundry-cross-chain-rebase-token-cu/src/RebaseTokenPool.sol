// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { TokenPool } from "@ccip/contracts/src/v0.8/ccip/pools/TokenPool.sol";
import { Pool } from "@ccip/contracts/src/v0.8/ccip/libraries/Pool.sol";
import { IERC20 } from "@ccip/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol"; // not the same interface from the token pool as IERC20 from oppenezeppelin
import { IRebaseToken } from "./interfaces/IRebaseToken.sol";

contract RebaseTokenPool is TokenPool {
    // 
    constructor(IERC20 _token, address[] memory _allowList, address _rnmProxy, address _router ) 
        TokenPool(_token, 
        // 18, 
        _allowList, _rnmProxy, _router) 
    {
    }

    function lockOrBurn(
        Pool.LockOrBurnInV1 calldata lockOrBurnIn
    ) external returns (Pool.LockOrBurnOutV1 memory lockOrBurnOut) 
    {
        // BURNMINTTOKENPOOLABRSTRACT
        _validateLockOrBurn(lockOrBurnIn); // is supported, is cursed, is allowed, etc

        // address receiver = abi.decode(lockOrBurnIn.receiver, (address));
        address originalSender = lockOrBurnIn.originalSender; // WHAT IF SENDING TO SMEONE ELSE, on function documented there is this originalSender explanation
        // address(i_token) casting intermediate address
        uint256 userInterestRate = IRebaseToken(address(i_token)).getUserInterestRate(originalSender);
        // address(this) = token pool when doing transfer. this requires to approve the router
        IRebaseToken(address(i_token)).burn(address(this), lockOrBurnIn.amount);
        lockOrBurnOut = Pool.LockOrBurnOutV1({
            destTokenAddress: getRemoteToken(lockOrBurnIn.remoteChainSelector), // remote token address, built in function to help us find it
            destPoolData: abi.encode(userInterestRate)
        }); // not really required to name but cleaner
    }

    function releaseOrMint(
        Pool.ReleaseOrMintInV1 calldata releaseOrMintIn
    ) external returns (Pool.ReleaseOrMintOutV1 memory)
    {
        _validateReleaseOrMint(releaseOrMintIn);
        uint256 userInterestRate = abi.decode(releaseOrMintIn.sourcePoolData, (uint256));
        // maybe log upper lines results since im not getting what it does
        IRebaseToken(address(i_token)).mint(releaseOrMintIn.receiver, releaseOrMintIn.amount, userInterestRate);

        return Pool.ReleaseOrMintOutV1({
            destinationAmount: releaseOrMintIn.amount
        });
    }
     
}