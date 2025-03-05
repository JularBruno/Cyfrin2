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
