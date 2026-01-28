# Section 4: Cross Chain Rebase Token

## Deployment to a testnet or mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file, similar to what you see in `.env.example`.

- `PRIVATE_KEY`: The private key of your account (like from [metamask](https://metamask.io/)). **NOTE:** FOR DEVELOPMENT, PLEASE USE A KEY THAT DOESN'T HAVE ANY REAL FUNDS ASSOCIATED WITH IT.
  - You can [learn how to export it here](https://metamask.zendesk.com/hc/en-us/articles/360015289632-How-to-Export-an-Account-Private-Key).
- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

1. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

2. Deploy

```
make deploy ARGS="--network sepolia"
```


### What Is-a-rebase-token
great explanation to read 
(accrued: received or accumulated in regular or increasing amounts over time.) 
- A rebase token is a cryptocurrency engineered with an elastic supply. This means its total circulating supply algorithmically adjusts rather than remaining fixed. These adjustments, commonly referred to as "rebases," are triggered by specific protocols or algorithms. The primary purpose of a rebase mechanism is to either reflect changes in the token's underlying value or to distribute accrued rewards, such as interest, directly to token holders by modifying their balances.
- Key Differentiators: Rebase Tokens vs. Standard Cryptocurrencies
The fundamental distinction between rebase tokens and conventional cryptocurrencies lies in how they respond to changes in value or accumulated rewards.

Rebase tokens can be broadly categorized based on their primary objective:
- Rewards Rebase Tokens: Value Stability Rebase Tokens: This category includes tokens designed to maintain a stable value relative to an underlying asset or currency (e.g., USD). 
- Value Stability Rebase Tokens: This category includes tokens designed to maintain a stable value relative to an underlying asset or currency (e.g., USD). Often associated with algorithmic stablecoins, these tokens adjust their supply to help maintain their price peg

- Crucially, while your token quantity increases, your proportional ownership of the total token supply remains unchanged. This is because every token holder experiences the same percentage increase in their balance.

- Real-World Application: Aave's aTokens Explained
One of the most prominent examples of rewards rebase tokens in action is Aave's aTokens. Aave is a leading decentralized lending and borrowing protocol.

Here’s how aTokens function within the Aave ecosystem:

- Depositing Assets: When you deposit an asset like USDC or DAI into the Aave protocol, you are essentially lending your cryptocurrency to the platform's liquidity pool.
- Receiving aTokens: In return for your deposit, Aave issues you a corresponding amount of aTokens (e.g., aUSDC for USDC deposits, aDAI for DAI deposits). These aTokens represent your claim on the underlying deposited assets plus any accrued interest.
- Accruing Interest via Rebase: The aTokens you hold are rebase tokens. As your deposited assets generate interest from borrowers within the Aave protocol, your balance of aTokens automatically increases over time. This increase directly reflects the interest earned.
- Redemption: You can redeem your aTokens at any time to withdraw your original principal deposit plus the accumulated interest, which is represented by the increased quantity of your aTokens.

Deep Dive: The Smart Contract Behind Aave's aTokens
github.com/aave-protocol/contracts/blob/master/contracts/tokenization/AToken.sol

- A key function in ERC-20 token contracts is balanceOf(address _user), which returns the token balance of a specified address. For standard tokens, this function typically retrieves a stored value. However, for rebase tokens like aTokens, the balanceOf function is more dynamic. It doesn't just fetch a static number; it calculates the user's current balance, including any accrued interest, at the moment the function is called.
- (included this because of scaled balance) Within Aave's AToken.sol contract, the balanceOf function incorporates logic to compute the user's principal balance plus the interest earned up to that point. It often involves internal functions like calculateSimulatedBalanceInternal (or similar, depending on the contract version and specific implementation details), which is crucial for dynamically calculating the balance including interest. This function effectively determines the "scaled balance" by factoring in the accumulated interest.

Rebase tokens, with their elastic supply mechanism, play a crucial role in various corners of the Web3 ecosystem, particularly within Decentralized Finance (DeFi). Understanding how they function is vital for anyone interacting with:

- Lending and Borrowing Protocols: As seen with Aave's aTokens, they provide an intuitive way to represent and distribute interest earnings.
- Algorithmic Stablecoins: Some stablecoins use rebasing to help maintain their price peg to a target asset.
- Yield Farming and Staking: Certain protocols might use rebase mechanics to distribute rewards.

By adjusting supply rather than price to reflect value changes or distribute rewards, rebase tokens offer a unique approach to tokenomics

### Rebase Token-code-structure
- Cross chain rebase token
1. a protcol that allows users to deposit into a vault and in return, receive rebase tokens that repesent their underlying balance
2. rebase token -> balanceOf function is dynamic to show the changing balance with time
    - Blance increaseas lineaarly with time
    - mint tokens to our users every time ther perform an action (minting, burning, transferring, or bridging)
3. Interest rate
    - individually set an interest rate or each user based on some gglobal interest rate of the protcol at the time the user desposit into the vault
    - this global interest rate cna only decrease to incentivise/reward early adopters
    - increase token adoption


### Writing The-rebase-token-contract

Should make some make file at least with the install
forge install openzeppelin/openzeppelin-contracts@v5.1.0

### Access Control

OpenZeppelin has `AccessControl` contract for fine-grained, role-based permissions.
- Allows to grant, revoke, get role addresses for different addressses
- There is a setAdmin! Ideal for prod contracts it makes more sense. The RebaseToken.sol has another structure
- onlyRole modifier to allow access to functions only be specified role
- deploy token, vault, and the cross chain functionality don't allow to set roles to addresses on constructor, mostly because security

### Vault And-natspec

Where users deposit their ETH and withdraw their ETH. Lockup all ETH in one place.

### Rebase Token Tests Part 1
- Should make unit tests, then integration tests to test scripts and everything, and then the fuzz tests. This projects holds them all together but is not a good practice.

### Vulnerabilities and Cross-chain Intro
The balanceOf shows a vulnerability, it has a compound interest that is not linear anymore as expected when user mints or burns. This is why this is a demo.

Cross-chain has a token standard in chainlink, mostly to be approved by the chains.

### Bridging

Literal brdige between chains that allows transfering anything like data, assets, tokens, NFTs, ETC. 
Gas fees to pay for transaction required, equally as having to pay in $pounds or $usds.

- bridging: The transfer of assets crosschain
- cross-chain messaging: any arbitrary data, it could be tokens like bridging but actually any data.

HOw does it work?
1. Burn and mint: total supply constant between chains
2. lock and unlock: vualts that have both tokens,leads to fragmented liquidity
3. lock and mint: locked tokens on source chain, and minted on destination chain eg USDC.e wrapped Basically an IOU
4. burn and unlock: reverse of lock and mint, burned on source and minted on destination

Avoid scentraliced bridges. trust entity to manage assets

- Descentralized bridges: trust minimized bridges. rely on network of people. 
- Chainlink ccip: move found through collection of descentrilized nodes. If node fails it is punished.
- native bridges: secure because of dveloped by platform team like zksync that build and manages the chain. slow.
- third party bridges: like arbiutrum, independently developed, liquidity pools, instalty get values in other side, high fees for paying for the provider. examples: ccip transporter, portal.
- cross chain is insecure, it probably should be multi chain. It is extremely used nevertheless. Expose your chain to audits to test it properly.

### CCIP

The Internet of Contracts
Different blockchains can interoperate securely and reliably. At its core, CCIP is a decentralized framework meticulously designed 
for secure cross-chain messaging. There were many rekt 

Basically bridging, descentralized, with specified nodes for defense 

Defense-in-depth security:
- off-chain rmn operations: one per blockchain mantaining group of nodes
- blessing: check source and destionation chain for matching messages
- cursing: detects anomaly and blocks the effected lane
- lane: pathway between source and destination chain, unidirectional
- token pools: abstractions of erc20, for minitng and burning or locking unlocking, and sets a rate limit (refill time and token )
- cct standard: create token and pools

the full CCIP graphic on the course displayed the path a transaction goes trhough

https://docs.chain.link/ccip/tutorials/evm/send-arbitrary-data
on course we did cool demostration on how to deploy contract and literally send data to eth from sepolia

### The CCT Standard

Enables developers to easily integrate tokens with CCIP, permissionles, keeping custody and control of token and pools

Reasons for this standard:
1. liquidity fragmentation: deploy token on chains and share liquidity
2. Token developer autonomy: integrate token without permission for a third party. 
3. programmable token transfers: send tokens and a message cross chain, useful for complex. requires locked liquidity.

Arquitecture:
- token contract: erc20 functionality
- token pool: logic for sending cross chain (stores logic for bridging). Also executes cross chain token transfers, does the bruning/locking and mintin/unlocking
- RegistryModuleOwnerCUstom: token admin
- TokenAdminRegistry: ccip enabled tokens 

Quick demo on building token and registering it.
VERY COOL ONE could attempt from ccip basic contract create one like the cyfrin repo:
- The last two Arquitecture above I think are for this project since it handles ccip setAdmin with owneable acceptAdminRol
- The Cuorse shows from basic like build and env required, to deploying both contracts in different chains
- burn and mint both in Sepolia and Arbitrum Sepolia
- setpool links tokens with pool enabling cross chain by setting remote token address
- You prepare a message for destionation
- Inspect transaction details on ccip chainlink
https://docs.chain.link/ccip/tutorials/evm/cross-chain-tokens/register-from-eoa-lock-mint-foundry
https://github.com/Cyfrin/ccip-cct-starter

### Circle CCTP

Well this is for using USDC as a Standard protcol to solve Cross-Chain main issues. It allow to really track USDC liquidity everywhere. It basically sets a protcol for not having a wrapped token (that should be USDC.e) in each different chain acting as an IOU.

Mechanism: Instead of locking USDC and minting a wrapped IOU, CCTP facilitates the burning (destruction) of native USDC on the source chain. Once this burn event is verified and finalized, an equivalent amount of native USDC is minted (created) directly on the destination chain.

Advantages of CCTP:
- Native Assets, No Wrapped Tokens: Users always interact with and hold native USDC, issued by Circle, on all supported chains. This completely eliminates the risks associated with wrapped tokens and their underlying collateral.
- Unified Liquidity: By ensuring only native USDC exists across chains, CCTP prevents liquidity fragmentation, leading to deeper and more efficient markets.
- Enhanced Security: CCTP relies on Circle's robust Attestation Service to authorize minting
- Permissionless Integration

Core Components of CCTP

- Circle's Attestation Service: This is a critical off-chain service operated by Circle. It acts like a secure, decentralized notary. The Attestation Service monitors supported blockchains for USDC burn events initiated via CCTP. After a burn event occurs and reaches the required level of finality on the source chain, the service issues a cryptographically signed message, known as an attestation. This attestation serves as a verifiable authorization for the minting of an equivalent amount of USDC on the specified destination chain.
- Finality (Hard vs. Soft)
- Fast Transfer Allowance (CCTP V2): This feature, part of CCTP V2, is an over-collateralized reserve buffer of USDC managed by Circle. When a Fast Transfer is initiated, the minting on the destination chain can occur after only soft finality on the source chain.
- this is like the core of the code !!! Message Passing: CCTP incorporates sophisticated and secure protocols for passing messages between chains. These messages include details of the burn event and, crucially, the attestation from Circle's Attestation Service that authorizes the minting on the destination chain.

1. Standard Transfer (V1 & V2 - Uses Hard Finality)

This method prioritizes the highest level of security by waiting for hard finality on the source chain.
- Basically emit attestation and receive attestation on chains

Step 5: Completion: The MessageTransmitter contract on the destination chain verifies the authenticity and validity of the attestation. Upon successful verification, it mints the equivalent amount of native USDC directly to the specified recipient address on the destination chain.

When to Use Standard Transfer: Ideal when reliability and security are paramount, and waiting approximately 13+ minutes for hard finality is acceptable. This method generally incurs lower fees compared to Fast Transfers.

2. Fast Transfer (V2 - Uses Soft Finality)

This method, available in CCTP V2, prioritizes speed by leveraging soft finality and the Fast Transfer Allowance.
- Allows minting before real burning
Step 5: Mint Event: The application fetches the (sooner available) attestation and submits it to the MessageTransmitter contract on the destination chain. The fee for the fast transfer is collected at this stage.
Step 6: Fast Transfer Allowance Replenishment: Once hard finality is eventually reached for the original burn transaction on the source chain, Circle's Fast Transfer Allowance is credited back or replenished.
Step 7: Completion: The recipient receives native USDC on the destination chain much faster, typically within seconds.

When to Use Fast Transfer: Best suited for use cases where speed is critical and the user/application cannot wait for hard finality. Note that this method incurs an additional fee for leveraging the Fast Transfer Allowance. (As of the video's recording, CCTP V2 and Fast Transfers were primarily available on testnet).

##### Ethersjs example:
approve, burn, retrieve message, fetch attestation
receive funds with attestation sighanture and message
cctp-vi-ethersjs
Transfer usdc on testnet From Ethereum to Avalanche

##### Minting allowence
Basically need to ask circle for more amount. TokenMinter

##### Advantages

- Fast cross chain rebalancing
- Composable cross chain swaps
- Simplify cross-chain complexities

### Pool Contract

forge install smartcontractkit/ccip@v2.17.0-ccip1.5.16

rmnProxy is risk managemnt network where they check nothing malicious is happening

### Chainlink Local and Fork Tests

Can not only work on tesing different forks, but also block numbers, allowing testing failures or hacks. 

For forking remmember to add toml rpc_endpoints, got them from alchemy. Just copied network from required for course abritrum sepolia and sepolia ethereum.

*Chainlink Local* is an installable package that allows you to run Chainlink services locally. https://docs.chain.link/chainlink-local

forge install smartcontractkit/chainlink-local@v0.2.5-beta.0

### Deploy Token Test

Based on the next chainlink tutorial on how to register burn and mint, we created the tests.

https://docs.chain.link/ccip/tutorials/evm/cross-chain-tokens/register-from-eoa-burn-mint-foundry


#### CCIP Setup Test
followed documentation but being applied to the test setUp. Use docs above.

#### Configure Pool Test
Remmember local and remote selection are based on the env you are working, think of it for testing, your local is the one you will be using and remote is the one receiving.

#### First Cross-chain Test

Remmember to add rpc_endpoints = {sepolia = "", arb-sepolia=""} in foundry toml
also env is required, will describe this at the top

#### Token and Pool Deployer

https://docs.chain.link/ccip/tutorials/evm/cross-chain-tokens/register-from-eoa-burn-mint-foundry

#### Bridging Script

Not going to build script for interaction, must be done with cast.
With CCIP you can catch messages and react to them.

#### Build Scripts

Added to foundry.toml:

via_ir = true

it used not to work, but now is useful

## Run Scripts on Testnet

Added from faucet:
Ethereum Sepolia Drips 25 LINK token address 0x779877A7B0D9E8603169DdbD7836e478b4624789 
ZKsync Sepolia Drips 25 LINK token address 0x23A1aFD896c8c8876AF46aDc38521f4432658d1e

Added to .env: ZKSYNC_SEPOLIA_RPC_URL since SEPOLIA_RPC_URL was already gotten from Alchemy before. Important add route with api key

And we gonna use SH bridgeToZksync.sh since scripts dont work

also had to create wallet account, called updraft in sh, so command is:
cast wallet import updraft --interactive

SH NOT WORKING many missmatches between versions i think, will review and deploy and then finish course

Lesson:
- At the time of this lesson, Foundry scripts (forge script) and their associated cheatcodes (e.g., vm.startBroadcast(), vm.stopBroadcast()) do not function reliably on ZKsync Sepolia. This is due to incomplete cheatcode implementation within the Foundry ZKsync integration. Fork testing ZKsync also faces similar limitations.

Unable to deploy on testnet

You can check the message on the ccip chain of the transfer made.

### Outro

Chiara resumes the full developed code.

Final quiz:

1. Before an external smart contract (like a bridge or router) can programmatically transfer a specific amount of an ERC20 token owned by another address or contract, what standard action must typically be performed first?
- The token owner must grant an allowance to the external contract, permitting it to spend the specified token amount on their behalf.

2. During the execution of complex smart contract tests involving numerous internal calls or deep contract interactions, what type of execution limit might be encountered, often necessitating compiler optimizations or code refactoring?
- Stack depth limit exceeded
Good question — short answer: yes, often --via-ir is the fix for stack-too-deep errors.

3. In Foundry tests, what does the `--via-ir` flag primarily address when running complex test suites?
- Potential 'Stack Too Deep' errors by enabling code optimization during compilation.

4. When configuring a `TokenPool` contract for cross-chain interaction with another `TokenPool` using CCIP, what information about the *remote* chain and pool is necessary?
- The remote chain's unique CCIP selector and the encoded address of the remote `TokenPool` contract.

5. When preparing a message payload for a CCIP message, how is the recipient's address formatted within the message structure?
- 
