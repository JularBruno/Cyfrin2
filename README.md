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

