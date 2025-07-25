// SPDX-License-Identifier: MIT

// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { DecentralizedStableCoin } from "./DecentralizedStableCoin.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title DSCEngine
 * @author BrunoJular 
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */

contract DSCEngine is ReentrancyGuard {

    //////////////////
    // errors
    ///////////////////
    // error DSCEngine__
    error DSCEngine__NeedsMoreThanZero();
    error DSCEngine__TokenAdressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine__NotAllowedToken();
    error DSCEngine__TransferFailed();
    error DSCEngine__BreaksHealthFactor(uint256 userHealthFactor);
    error DSCEngine__MintFailed();
    error DSCEngine__HealthFactorOk();
    error DSCEngine__HealthFactorNotImproved();

    //////////////////
    // state variables
    ///////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1e18;
    uint256 private constant LIQUIDATION_BONUS = 10; // this meansd 10% bonus

    mapping(address token => address priceFeed) private s_priceFeeds; // tokenToPriceFeed s_tokenToAllowed
    mapping(address user => mapping (address token => uint256 amount)) 
        private s_collateralDeposited; 
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;

    DecentralizedStableCoin private immutable i_dsc;


    //////////////////
    // events
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);
    event CollateralRedeemed(address indexed redeemFrom, address indexed redeemTo, address indexedtoken, uint256 amount);

    //////////////////
    // modifiers
    ///////////////////
    modifier moreThanZero(uint256 amount) {
        if(amount == 0) {
            revert DSCEngine__NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if(s_priceFeeds[token] == address(0)) {
            revert DSCEngine__NotAllowedToken();
        }
        _;
    }

    // modifier isAllowedToken(address token) {
    //     if(token  == 0) {
    //         revert DSCEngine__NeedsMoreThanZero();
    //     }
    //     _;
    // }


    //////////////////
    // functions
    ///////////////////

    /**
     * 
     * @param tokenAddresses a
     * @param priceFeedAddresses USD Price Feeds (each pair of crypto w usd)
     * @param dscAddress DescentralizedStableCoin address
     */
    constructor(
        address[] memory tokenAddresses, 
        address[] memory priceFeedAddresses,
        address dscAddress
    ) {
        if(tokenAddresses.length != priceFeedAddresses.length) {
            revert DSCEngine__TokenAdressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }

        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    //////////////////
    // external functions
    ///////////////////

    /**
     * 
     * @param tokenCollateralAddress The address of the token to deposit as collateral
     * @param amountCollateral The amount of collateral to deposit
     * @param amountDscToMint The amount of DSC to mint
     * @notice this function will deposit collateral and mint DSC in one transaction
     */
    function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToMint) external 
        // moreThanZero(amountCollateral) moreThanZero(amountDscToMint) isAllowedToken(tokenCollateralAddress) nonReentrant 
    {
        depositCollateral(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);

    }

    /**
     * @notice follows CEI
     * @param tokenCollateralAddress the address of the token to deposit as collateral
     * @param amountCollateral  the amount of collateral to deposit
     */
    function depositCollateral(
        address tokenCollateralAddress, 
        uint256 amountCollateral
    ) 
        public 
        moreThanZero(amountCollateral) 
        isAllowedToken(tokenCollateralAddress) 
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral; // updating state so emit
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!success) {
            revert DSCEngine__TransferFailed();
        }

    }

    /**
     * 
     * @param tokenCollateralAddress The collateral address to redeem
     * @param amountCollateral The amount collateral to redeem
     * @param amountDscToBurn The amount of DSC to burn
     * @notice this function will burn DSC and redeems underlying collateral in one transaction
     * also requires refactor
     */
    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn) 
        external moreThanZero(amountCollateral) 
        // this was non reentrant throwing an error on testing, since next functoins also have it 
    {
        burnDsc(amountDscToBurn);
        redeemCollateral(tokenCollateralAddress, amountCollateral);
        // redeemCollateral already checks health factor

    }

    // in order to redeem collateral
    // 1. health factor must be over 1 AFTER colllateral pulled
    // DRY: Dont repeat yourself (we are gona refactor this )

    // CEI: Checks, efects, interactions (this will be violated because calculate health factor required)
    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) 
        public 
        moreThanZero(amountCollateral)
        nonReentrant
    {
        /* REMOVED next code because of refactor, left it here for understanding the changes */
        // solidity reverts unsafe math, like having less than requering to redeem
        // s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral;
        // emit CollateralRedeemed(msg.sender, amountCollateral, tokenCollateralAddress);

        // bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, amountCollateral); // transfer from self
        // if(!success) {
        //     revert DSCEngine__TransferFailed();
        // }

        _redeemCollateral(tokenCollateralAddress, amountCollateral, msg.sender, msg.sender);
        _revertIfHealthFactorIsBroken(msg.sender); // for retrieving my hole amount if I have DSC I need to do two transactions, burn dsc then redeem eth
    }

    // 1. Check if the collateral value > DSC amount.
    /**
     * 
     * @param amountDscToMint the amount of DSC to mint
     * @notice they must have more collateral than the minimun threshold
     */
    function mintDsc(uint256 amountDscToMint) 
        public moreThanZero(amountDscToMint) nonReentrant
    {
        s_DSCMinted[msg.sender] += amountDscToMint;

        // if they minted too much($150 DSC and 100 ETH)
        _revertIfHealthFactorIsBroken(msg.sender);

        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if(!minted) {
            revert DSCEngine__MintFailed();
        }
    }

    
    function burnDsc(uint256 amount) public moreThanZero(amount) nonReentrant {
        /* REMOVED on behalf of refactor */
        // s_DSCMinted[msg.sender] -= amount;
        // bool success = i_dsc.transferFrom(msg.sender, address(this), amount);
        // // this conditional is hypotetically unreacheable
        // if(!success) {
        //     revert DSCEngine__TransferFailed();
        // }
        // i_dsc.burn(amount);

        _burnDsc(amount, msg.sender, msg.sender);
        
        _revertIfHealthFactorIsBroken(msg.sender); // this whole function breaks health factor? probably not, this just in case
    }

    // If we do start nearing undercollateralization, we need someone to liquidate positions
    // 100 eth backing 50 dsc, and then eth 20 eth backing 50 dsc, then dsc is not worth enough
    // If someone is almost undercollateralized, we will pay you to liquidate them!
    // 75 backing 50 dsc, liquidator take 75 backing and burns off the 50 dsc

    /**
     * @notice To maintain the protocol's solvency by allowing the removal of undercollateralized positions.
     * @param collateral the erc20 collateral address to liquidate from the user
     * @param user the user who has broken the health factor. Their _healthFactor is should be bellow MIN_HELTH_FACTOR
     * @param debtToCover The amount of DSC you want to burn to imporve the user health factor
     * @notice You can partially liquidate a user
     * @notice You will get a liquidation bonus for taking the users funds
     * @notice This function working assumes the protcol will be roughly 200% overcollateralized in order for this to work
     * @notice A known bug would be if the protocol was only 100% collateralized, we wouldn't be able to incentivize the liquidators.
     * For example, if the price of the collateral plummeted before anyone could be liquidated.
     */
    function liquidate(address collateral, address user, uint256 debtToCover) 
        external 
        moreThanZero(debtToCover)
        nonReentrant    
    {
        // Follows CEI: checks, effects, interactions
        // 1. check health factor of the user
        uint256 startingUserHealthFactor = _healthFactor(user);
        if(startingUserHealthFactor >= MIN_HEALTH_FACTOR) {
            revert DSCEngine__HealthFactorOk();
        }
        // we want to burn their dsc "debt" and take their collateral
        // bad user 140 eth and 100 dsc, debt to cover is 100 dsc, how much eth?
        uint256 tokenAmountFromDebtCovered = getTokenAmountFromUsd(collateral, debtToCover);
        // And give them a 10% bonus
        // So we are giving the liquidator $110 of WETH for 100 DSC
        // We should implement a feature to liquidate in the event the protocol is insolvent
        // And sweep extra amounts into a treasury
        uint256 bonusCollateral = (tokenAmountFromDebtCovered * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;
        uint256 totalCollateralToRedeem = tokenAmountFromDebtCovered + bonusCollateral;
        
        _redeemCollateral(collateral, totalCollateralToRedeem, user, msg.sender);
        _burnDsc(debtToCover, user, msg.sender);

        uint256 endingUserHealthFactor = _healthFactor(user);
        if(endingUserHealthFactor < startingUserHealthFactor) {
            revert DSCEngine__HealthFactorNotImproved();
        }

        _revertIfHealthFactorIsBroken(msg.sender);
    }



    //////////////////
    // private and internal view functions
    ///////////////////

    /**
     * @dev low level internal function, do not call unless the function calling it is checking for health factors being broken
     * @param amountDscToBurn amount
     * @param onBehalfOf behalf
     * @param dscFrom from
     */
    function _burnDsc(uint256 amountDscToBurn, address onBehalfOf, address dscFrom) 
        private
    {
        s_DSCMinted[onBehalfOf] -= amountDscToBurn;
        bool success = i_dsc.transferFrom(dscFrom, address(this), amountDscToBurn);
        // this conditional is hypotetically unreacheable
        if(!success) {
            revert DSCEngine__TransferFailed();
        }

        i_dsc.burn(amountDscToBurn);
    }

    /**
     * @notice To allow users to withdraw their deposited collateral, provided their position remains sufficiently collateralized
     * @param tokenCollateralAddress a
     * @param amountCollateral a
     * @param from a
     * @param to a
     */
    function _redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral, address from, address to) 
        private 
    {
        s_collateralDeposited[from][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(from, to, tokenCollateralAddress, amountCollateral);    

        bool success = IERC20(tokenCollateralAddress).transfer(to, amountCollateral); // transfer from self
        if(!success) {
            revert DSCEngine__TransferFailed();
        }
    
    }

    function _getAccountInformation(address user) private view returns (uint256 totalDscMinted, uint256 collateralValueInUsd) {
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }

    /** 
     * Returns how close to liquidation the user is.
     * if the user goes bellow 1, they can get liquidated.
     * @notice To quantify the safety margin of a position by comparing collateral value to debt value.
     */
    function _healthFactor(address user) private view returns (uint256 healthFactor) {
        // total DSC minted
        // total collateral VALUE
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        // return (collateralValueInUsd / totalDscMinted); // (150 / 100) // this requires liquidation threshold

        // this fixes the bug detected in the tests and required by the course
        if (totalDscMinted == 0) {
            return type(uint256).max;
        }

        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        // the math here is easy, 150 * 50 = 7500 / 100 = 75 , this means undercollateralized becase its under the double threshold required
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted; // true health factor, if this less than 1 you can get liquidated
    }

    function _revertIfHealthFactorIsBroken(address user) internal view {
        // 1. check health factor (do they have enough collateral?)
        // 2. revert if they dont have a good health factor (AAVE health factor)
        uint256 userHealthFactor = _healthFactor(user);
        if(userHealthFactor < MIN_HEALTH_FACTOR) {
            revert DSCEngine__BreaksHealthFactor(userHealthFactor);
        }
    }

    function _calculateHealthFactor(
        uint256 totalDscMinted,
        uint256 collateralValueInUsd
    )
        internal
        pure
        returns (uint256)
    {
        if (totalDscMinted == 0) return type(uint256).max;
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
    }

    //////////////////
    // public and External view functions 
    ///////////////////

    function getTokenAmountFromUsd(address token, uint256 usdAmountInWei) 
    public view returns (uint256 ) 
    {
        // price of token
        // $/eth eth ??
        // $2000 / 1000 eth = 0.5 eth
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int price, , , ) = priceFeed.latestRoundData();
        // ($10e18 * 1e18) / ($2000e8 * 1e10)
        return (usdAmountInWei * PRECISION) / (uint256(price) * ADDITIONAL_FEED_PRECISION);
    }

    function getAccountCollateralValue(address user) public view returns (uint256 totalCollateralValueInUsd) {
        // loop through each collateral token, get the amount they have deposited, and map it to
        // the price, to get the USD value
        for (uint i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            totalCollateralValueInUsd += getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd; // remmember this not required but cleaner
    }

    function getUsdValue(address token, uint256 amount) public view returns (uint256 usdValue) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int price, , , ) = priceFeed.latestRoundData();
        // 1 eth = $1000
        // the return value from CL will be 1000 * 1e8
        return ((uint256(price) * ADDITIONAL_FEED_PRECISION) * amount) / PRECISION; // (1000 * 1e8 * (1e10)) * 1000 * 1e18; same units of precition  
    }

    function getAccountInformation(address user) external view returns (uint256 totalDscMinted, uint256 collateralValueInUsd) {
        (totalDscMinted, collateralValueInUsd) = _getAccountInformation(user);
    }
    
    function getHealthFactor(address user) external view returns (uint256 userHealthFactor) {
        return _healthFactor(user); 
    }

    function minHealthFactor() public pure returns (uint256) {
        return MIN_HEALTH_FACTOR;
    }

    function getLiquidationThreshold() external pure returns (uint256) {
        return LIQUIDATION_THRESHOLD;
    }

    function getLiquidationPrecision() external pure returns (uint256) {
        return LIQUIDATION_PRECISION;
    }

    function getCollateralTokens() external view returns (address[] memory) {
        return s_collateralTokens;
    }

    function getCollateralBalanceOfUser(address user, address token) external view returns(uint256) {
        return s_collateralDeposited[user][token];
    } 

    function calculateHealthFactor(
        uint256 totalDscMinted,
        uint256 collateralValueInUsd
    ) // this can be used to check expected health factor in tests
        external
        pure
        returns (uint256)
    {
        return _calculateHealthFactor(totalDscMinted, collateralValueInUsd);
    }
}