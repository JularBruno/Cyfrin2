# Section 4: Cross Chain Rebase Token

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

