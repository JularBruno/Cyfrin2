# Solidity Smart Contract Development 

Solidity Smart Contract Development is made and executed on
https://remix.ethereum.org/

# Foundry fundamentals 

Other courses and interests beside Cyfrin
https://speedrunethereum.com/challenge/simple-nft-example
https://docs.prylabs.network/docs/install/install-with-script


### For using foundry on windows:

- install wsl
- install remote connector in vs code
- use remote conector to access ubuntu wsl

mount windows folder:
```
cd /mnt/c/Users/YourUsername/Projects/Cyfrin/
```

### Ganache, Anvil, and metamask setup
https://updraft.cyfrin.io/courses/foundry/foundry-simple-storage/deploy-smart-contract-locally?lesson_format=transcript

```
/Downloads$ sudo ./ganache-2.7.1-linux-x86_64.AppImage
```

### Deploy a smart contract locally using Forge
Default rpc url is Anvil 
```
forge create SimpleStorage --interactive --broadcast
```

#### deploy contract local onchain WITH ENV

forge script script/DeploySimpleStorage.s.sol --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY

#### deploy contract local onchain WITH cast wallet list

- this after cast wallet import defaultkey --interactive
```
forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --account defaultkey --broadcast -vvvv
```
### broadcast -> dry-run -> transaction

- stored transaction pieces
- gas quick calc: ```cast --to-base 0x71556 dec```
- nonce: data for rerun transaction

## Deploy a smart contract locally using Anvil
It is essential to distinguish Solidity as a contract language from Solidity as a scripting language.

Created DeploySimpleStorage.s.sol
```
forge script script/DeploySimpleStorage.s.sol --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://127.0.0.1:8545
```

## Never Use A Env File
you can .env with this
```
PRIVATE_KEY=
RPC_URL=http://127.0.0.1:8545
```

Next run `source .env`

Foundry has a very nice option called `keystore`.

```
cast wallet import anvil0 --interactive
forge script script/DeploySimpleStorage.s.sol --rpc-url http://127.0.0.1:8545 --broadcast --account anvil0 --sender 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
```
```
cast wallet list
```

### how to setup cast wallet on dotenv

- Interact with a smart contract using the CLI (contract always is the same)
```
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "store(uint256)" 123 --rpc-url http://127.0.0.1:8545 --account anvil0

cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "retrieve()"

cast --to-base 0x000000000000000000000000000000000000000000000000000000000000007b dec
```

### Deploying a smart contract on testnet (Sepolia)

- alchemy setup
- settedup cast wallet metamask on actual metamask wallet

```
forge script script/DeploySimpleStorage.s.sol --rpc-url https://eth-sepolia.g.alchemy.com/v2/9Yi86zPO8rSrihsldwaChOAm-MvfKaPf --account metamask --broadcast
```
https://sepolia.etherscan.io/tx/0xba0637fb5f5df170200bfae114db3b83644e0c52551502908d9d4d40f7894e10

#### Foundry Zksync

ZKsync uses unique opcodes
```
foundryup-zksync
forge --version
forge build .sol -- --zksync

```
back to normal
```
foundryup
forge --version
```
didnt check because tutorial is going arround everywhere, heres to deploy to zksync
forge create src/SimpleStorage.sol:SimpleStorage --rpc_url <RPC_URL> --private_key <PRIVATE_KEY> --legacy --zksync

#### Tx Types, Why L2, Alchemy

*Types* seen on broadcast folder transactions (0x0 0x2), differ on the functionality of the contract. There are many and change between zksync and anvil deploys.

Most projects today prefer deploying to *Layer 2* solutions rather than directly to Ethereum due to the high costs associated with deployments
- gasUsed: allows us to estimate the deployment cost on the Ethereum mainnet
- Deploying to ZKsync Sepolia is similar to deploying to a ZKsync local node

Think of *Alchemy* as the AWS of Web3.
- The platform's primary component is the _Supernode_, a proprietary blockchain engine that works as a load balancer on top of your node.

# Section 2: Foundry Fund me

### Writing tests for your Solidity smart contract

`forge test` has an option called verbosity. By controlling this option we decide how verbose should the output of the `forge test` be.
```
forge test -vv
```

### Running tests on chains forks

This course will cover 4 different types of tests:

* **Unit tests**: Focus on isolating and testing individual smart contract functions or functionalities.
* **Integration tests**: Verify how a smart contract interacts with other contracts or external systems.
* **Forking tests**: Forking refers to creating a copy of a blockchain state at a specific point in time. This copy, called a fork, is then used to run tests in a simulated environment.
* **Staging tests**: Execute tests against a deployed smart contract on a staging environment before mainnet deployment.

Coming back to our contracts, the central functionality of our protocol is the `fund` function.
So for price checking we want to see if we can get conversion rate. Firstly checking AggV3 version


This are unit and integration, tests.

```
forge test --mt testPriceFeedVersionIsAccurate
```

This above fails, need to fork. Created .env with alchemy SEPOLIA_RPC_URL
We can add `-vvv` to see stack trace.

This runs as anvil simulating sepolia. 

```
source .env
forge test --mt testPriceFeedVersionIsAccurate --fork-url $SEPOLIA_RPC_URL
```
#### Deploy a mock priceFeed

```
forge test --fork-url $MAINNET_RPC_URL -vvv
```

#### Introduction to Foundry Chisel
To test small code just run `chisel`

### Calculate Withdraw gas costs

```
forge snapshot --mt testWithDrawFromMultipleFunder -vvv
```

.gas-snapshot is creted and says how many gas is a test gona cost

Anvil default gas price is 0!


## Introduction to Storage optimization

First method for optimization, Storage.

Storage: giant array of variables created. 
- Each slot is 32 bytes long.
- Dynamic elements, like array of mapping, these use a hashing function. An array just stores its length, and when you push this occupies a place in stroage being a hashing function. 
- Constant variables don't use space in storage because this are in the bytecode of the contract. Is just like a pinter to the value.
- Variables inside function are not in storage either, these are deleted after the function closes.
- We use memory when using strings, strings are technically an array.
- Solidity wants to know where to store the variable, storage or memory, needs to know where to allocate space.

check DeployStorageFun.s.sol to play with storage spots

```
forge inspect FundMe storageLayout
```
- Constant and immutable are part of the contract bytecode


```
cast storage contractId 2
```
Prints what is at storage index 2

### Optimise the withdraw function gas costs
`object` contract in pure bytecode
`opcodes` low level codes for computing in low level assembly, each one has specific gas codes

evm.codes
- `sload store` is very expensive, everytime you read from storage it spends a minimum of 100gas
- `mload and mstore` read and write to memory only cost 3 gas

this retrieves the difference
```
forge snapshot
```
take in consideration styles: i_ immutable, s_ storage, uppercase for constants

read style guide on soliditylang

#### Create integration tests
```
forge install Cyfrin/foundry-devops --no-commit
```

`ffi = true` foundry code into machine

for calling fund
```
forge script script/Interactions.s.sol FundFundMe --rpc-url --private-key
```
we did the tests for this

### Automate your smart contracts actions - Makefile

- ETHERSCAN_API_KEY: Went through etherscan.io process to get an api key, pasted it in ENV, maybe can use cast wallet for best practices.
- PRIVATE_KEY: Private key from metamask! Thats why we use env

Had some issues, when random error run with `--force` a deploy then run again the.

```
make deploy-sepolia
```

Had an error verifying the contract, don't really car now.

#### ZkSync Devops

```
make remove
make install

forge test --mt testZkSyncChainFails -vvv

foundryup-zksync
```

- foundry-devops package has very important features!
- zksynchainchecker: has functions or modifiers to use or skip test when --zksync

```
contract ZkSyncDevOps is Test, ZkSyncChainChecker, FoundryZkSyncChecker {
    function testZkSyncChainFails() public skipZkSync { 
```

- skipZkSync is for skipping the test, zksync doesnt support so skip them
- this for not havy many failed tests, or if test fails in some env, slip it

- FoundryZkSyncChecker: tests can also fail because of foundry version thats why we can use this

- onlyOnVanillaFoundy: only works on vanilla even when no specifying `--zksync` but with `foundryup-zksync` already doesnt support all vanilla foundry things

# Section 3: Foundry me Frontend

https://github.com/Cyfrin/html-fund-me-cu

A beginner's guide to interacting with a website using your MetaMask wallet. The lesson covers the importance of understanding how your wallet interacts with websites, especially when sending transactions.

### How Metamask interacts with dapps

Install live server extension or open index.html on the browser, this is for interacting with the MetaMask.
Had to install live server because of cors.

- use `make anvil` otherwise it wont work!
- window.ethereum: this comes with metamask, even has wallet selected data. Read metamask docs.
- use connect button to connect wallet
- constants has contractAddress hardcoded in
- this has ethers pacakge to interact with metamask and contracts
    -  throws request via rpc url in metamask environmet
- make deploy
    - contract FundMe contract <address>
- Setup metamask with anvil rpc url, also set up acocunt of anvil
- abi constants: functions that can be called from contract
- private key is always on metamask!

### Decoding Ethereum transactions

- metamask actually calls function selector with function signature (hex) `cast sig "fund()"` on the rpc url
- should be able to see hex of the transaction "fund"
- constants have the functions names in the abi
- can be used to check function in frontend is running the properone
- if parameters hex bigger, for calling with params `cast call-decode "fund()" param`

# Section 4: Smart Contract Lottery

#### Solidity style guide
https://docs.soliditylang.org/en/latest/style-guide.html#order-of-layout
https://docs.soliditylang.org/en/latest/style-guide.html#order-of-functions

### Smart contracts events

Which data structures use to keep track of players? Arrays, mapping or
Events:
- Make migration and front end indexig easier
- EVM -> logging: events emit logs -> datastructure for logs -> you can eth_getLogs -> events allow to log, special datastructure not for smart contracts -> tied to smart contract -> we want to listen events -> ideal for offchain infrastructure -> chainlink helps with this reading, and the graph does it for even bigger event data structure
- event structure: event type ie uint256 has four paramenters
    - indexed keyword: up to three topics, this are easier to search and query
        - the non indexed ones are abi encoded
- we need to emit event to log it `emit event(parameters)`
- There are event transactions
    - these have address, data and a few more
    - non indexed events are gas cheaper

### Random numbers - Introduction to Chainlink VRF

- https://docs.chain.link/vrf/v2-5/subscription/get-a-random-number
- Create Chainlink subscription
- So this chanilink video say too many things but I dont fully require them
    - Basically setup vrf subscription but requires to validate contract using it
    - There is a conf for random values, how to store them, and security behind it like really being random or knowing the result beforehand than the contract

### Implement the Chainlink VRF

- Docs 
    - V2 Subscription Method: singular subscription contract, sending gas to each fund
    - Direct funding methid: fund the contract, every time we deploy raffle we should pay
- Two transactoin process, first request RNG then get RNG
- Instal chainlink-brownie-contracts, remmember to change the foundy.toml to link @chainlink
- We need to add inherited contract, and constructor
- on the docs there are all the explanations to the _struct_ of the vrf
- `forge fmt`

### Implementing Vrf Fulfil
We are requesting to chainlink, inheriting the contract VRFConsumerBaseV2Plus, there is a contract already deployed that can be requested a random number.

### The modulo operation
- The mod function: divide and get the remainder 10/9 = 1.?

### Implementing the lottery state - Enum
Enum state

### The CEI method - Checks, Effects, Interactions
Sometimes called "FREI-PI" Function requirements, effects-interactions, protocol INVARIANTS
Helps avoid reentrancies.

CEI: Checks, effects, interactions pattern
- Checks (requires, conditional) more gas efficient to revert early
- Effect (internal contract state) 
- Interactions (External Contract Interactions) 

### Introduction to Chainlink Automation (or chainlink keepers)

We are not automatically calling pickWinner yet.
We are going to use chainlink automation.
https://docs.chain.link/chainlink-automation/overview/getting-started
https://docs.chain.link/chainlink-automation/guides/compatible-contracts

- Before the contracts required a checkUpkeep and performUpkeep to make any cron job, now Chainlink automations are used for that
- Chainlink needs a contract abi to create an automation
- Then in chainlink select time based and use cron to 
    - there are cron readeable translators
    - set the cron ie 1 **** one minute
    - select contract function
- Setup automation or upkeep

### Subscribing to events

Very cool how he analized this error

```
Failing tests:
Encountered 1 failing test in test/unit/RaffleTest.t.sol:RaffleTest
[FAIL: InvalidConsumer(0, 0x90193C961A926261B756D1E5bb255e67ff9498A1)] testDontAllowPlayersWhileRaffleIsCalculating() (gas: 106811)
```

Raffle::performUpkeep()
    │   ├─ [5388] VRFCoordinatorV2_5Mock::requestRandomWords()
    │   │   └─ ← [Revert] InvalidConsumer(0, 0x90193C961A926261B756D1E5bb255e67ff9498A1)

- Searched from revert into VRF Contract, found onlyValidConsumer -> consumer not added or sth
    - Previous notes that where confusing about VRF Setup, now make sense
    - You have to create a subscription and then add a consumer
- We need to update deployment process
- https://openchain.xyz/ signature database, hex data for name
- `cast sig "createSubscription()"` 0xa21a23e4

### Creating the subscription UI

We basically followed the steps on https://vrf.chain.link/ to create a subscription, but instead of doing it on the ui we can make a script out of it like in Interactions.s.sol

- create subscription, you will be seeing it on My Subscriptions. You have a subscription Id to copy
- You need to fund the subscription, Sepolia is the net being used. Fund subscription button on subscription.
    - [https://docs.chain.link/resources/link-token-contracts -> ](https://docs.chain.link/resources/link-token-contracts#sepolia-testnet)
    - for local linktoken.sol 
        - need to copy from https://github.com/Cyfrin/foundry-smart-contract-lottery-cu/blob/main/test/mocks/LinkToken.sol
        - need to install solmate

#### Fund subscription
```
source env 
cast wallet

forge script script/Interactions.s.sol:FundSubscription 
--rpc-url $SEPOLIA_RPC_URL --account sepolia --broadcast
```

- or use --private-key
- But we mocked everything to do it locally to test it.
- Scripts are also required to be tested.
- I just tested it locally! 

#### Coverage Report
```
forge coverage --report debug > coverage.txt
```

Challenge: Figure how to cover all tests

testCheckUpKeepReturnsFalseIfEnoughTimeHasPassed
testCheckUpKeepReturnsTrueWhenParametersAreGood

### Intro to fuzz testing

Using random inputs for testing smart contracts, emphasizing the importance of mock functions and fuzz testing for secure and stable systems.

- DEFAULT ALL TESTS TO FUZZ IF POSSIBLE
- When runned we can see (runs: 256, μ: 82444, ~: 82444) and here it says that it tried 256 times.
- Can be modified in toml, with fuzz to run as many times as required.
- Some weird scenarios can be tested with many more fuzz times test, leaving it in background running.

#### Forked test environment and dynamic private keys

- Running locally does random private key
- start broadcast can have an address or account
- Created dynamic account for each env
    - locally it uses always the same account, copied from Base.sol of forge-std 
    - for the fork url it should have the metamask asociated with alchemy account

### Deploy the lottery on the testnet pt.1


This was a headache. 

- Make sure you have your env with SEPOLIA_RPC_URL and ETHERSCAN_API_KEY. This are from alchemy and etherscan sepolia. 
- Create a "default" account as a cast wallet so you can call it, it must have your wallet used in alchemy, seplolia, and chainlink.
- Chainlink VRF must be seted up, funded and you can run the make
- Make `make deploy ARGS="--network sepolia"` should work to deploy the contract and create the consumer on VRF. This was all very slow and bugged.
- RUn this since verifying wont be possible by command, at least I couldnt make it work. GO to your contract on sepolia etherscan and search for validatoin. Use the json.json to finish the form. 

```
forge verify-contract 0xA12e8d7072a640c2a292905a9d1939238937855D src/Raffle.sol:Raffle --etherscan-api-key $ETHERSCAN_API_KEY --rpc-url $SEPOLIA_RPC_URL --show-standard-json-input > json.json
```

- After verifying the raffle contract can be written in etherscan.
- It again took some time but vrf, automation, and the contract in etherscan are working. The last step would be to see the recent winner.

- Should have deployed anvil first. To test properly and we saw many times that first anvil, then stage, then some prod env.

### Implementing console log in your smart contract, Debug using forge test

Console log from forge std can be used on contract.
Remove them for deploy, it even costs gas!

`forge test --debug` very useful for advanced debugging.

###
- https://automation.chain.link/
- https://vrf.chain.link/
- https://sepolia.etherscan.io/address/0xA12e8d7072a640c2a292905a9d1939238937855D#readContract
