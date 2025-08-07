Stablecoin
1. Relative staility: Anchored or pegged to usd dolar (floating is difficult)
    1. chainlink price feed
    2. set function to exchange eth and btc to any usd value around a dolar
2. Stability mecanism (minting): algorithmic (decentralized)
    1. people can only mint stablecoin with enough collateral (coded)
3. Collateral: exogenous (crypto)
    1. weth (weth Wrapped eth)
    2. wbtc


## Section 3: Develop a DeFi Protcol

Bankless.com
metamask learn
try aave and u uniswap

### DeFi introduction
its hard, best for being cool at programming
- DeFiLlama has the examples, since we are going to introduce defi functionalities. 
- Aave shows example of how staking coins gives assets, and its because some people is borrowing those assets. Premisionless baking and borrowing of assets.
- Uniswap just allows to swap assets premisionless descentralized.
- MEV plays the defi industry, concept is if you validate transactions helps you create protcol to help you. Terrifying and useful
- makerdao: dao token, actually what people work with and create.
- defi: mainly Premisionless, opensource finance.

defi to take over the world

### Project code walkthrough
Two main files 
- DecentralizedStableCoin.sol has Burn mint
- main file DSCEngine.sol controls the DecentralizedStableCoin.sol
- Stablecoin works because of collaterals
- you can redeem remove burn liquidated mintDsc
- also test folder
- mocks
- fuzz tests also
- scripts as well
- primitives and products are all included here
Stablecoins what really are:

### Introduction to stablecoins
non volatile crypto assets, value fluctuates very little. Is not necessary pegged to some real asset.
low volatility fulfills (use dollars as example for next things)
- storage value
- unit of account
- medium of exchange

web3 money desentralized money for following previous qualities

categories of stablecoins (not necessary categorized like usual media)
- relative stability: pegged anchored or floating(not tied) to another asset. This could be even more stable to real value against inflationary assets. There is algorithmic based coins that are more stable to buying power https://reflexer.finance/

- stability method: governed or algorithmic. minting or burning, who or what does it. Governed = single person/entity. Algorithmic = permissionles algorithmic without intervetion for minting and burning. Hybrid ones Also includes DAO for voting interest rates and many more things.

- collateral type: stuff backing our stablecoin. Exogenous collateral originates from outside, Endogenous from inside.
If stablecoin fails, does the underlying collateral also fail.
Owns issuance of collateral? UST is a good example (terra luna fail).
Ideally these are overcollateralised. DAI is mor exo, frax is goodly divised, ust plumb was because it was mostly endo.
Scalability: Exo can only have stalecoin marketcap as high than that of your collateral. Endo not necessary. (exo can scale)

This video explains the position DAI occupies in the spectrum of the behaivours mentioned above. Also how it bases its collateral, allows minting less than actual assets, why it burns, and has a stability fee (collateralized debt position) if collateral is not up people can liquidate (also people vote). 

leverage investing is what drives people to mint this stablecoins,Allows to exposure to other assets.

#### DecentralizedStableCoin.sol
Is ERC20Burnable, because it has a Burn function, ideal for maintingin peg price
Goberned by our engine (has its abilities, collateral minting stability)

super calls super class or parent class

#### Project setup - DSCEngine

liquidate function is usefull since collateral value can descend, so when this happens, the DSC(the coin created) minted, can be liquidated to save protcol by removing people from the position of DSC

For not being undercollateralized you can set a buffer, called a treshold, of 150% (ie if im holding 50 bucks there should be 75 for my collateral). THis could even be rewarded (holding collateral) because could save people that need to be liquidated

could comment all functions of DSCEngine before starting, could create the script for testing with it, should create tests along

#### Create the deposit collateral function

desposit is the first thing people would do


Reentrantcy are the most common attacks, all functions might need to be non reentrant by default. when working with outside contracts

### Create the fuzz tests handler pt.1
1. what are our invariants/properties?

Fuzz/invariant testing video:

- Fuzz is to supply random data in attempt to break system.
- invariant: property of our system that should always hold
- symbolic executoin/formal verirification: other type of validation for verificatoin
- for fuzzing just define variabels fo the test and dont set value
- stateless fuzzing is default where previous test is discarded
    - stateful fuzzing final state of previous test, is now the starting state of next run "invariant_" (random function and data calls)

- USE Handler based 

#### Debugging the fuzz tests handler

- ghost function to check where mint is called
- forge inspect DSCEngine methods

#### Create the price feed handler

COOL BUG we found that when price changes abruplty it makes system collapse
// calldata=updateCollateralPrice(uint96) args=[2499]
also we read some errors together with Patrick

price feed should be between and we found that with invariant tests
// 200% <-> 110%

#### Finished Section 3
https://lens.xyz/ very useful for governance and make some social app

https://docs.soliditylang.org/en/latest/natspec-format.html 
NatSpec Format essential guide for clean solidity programming 

### 

forge script script/DeployDSC.s.sol:DeployDSC --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545
cast call 0x0165878A594ca255338adfa4d48449f69242Eb8F "getLiquidationThreshold()(uint256)" --rpc-url http://localhost:8545

cast call 0x0165878A594ca255338adfa4d48449f69242Eb8F "getCollateralTokens()(address[])" --rpc-url http://localhost:8545