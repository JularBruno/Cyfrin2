## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# Advanced foundry

## Develop an ERC20 Crypto Currency

### Introduction to ERC fundamentals and ERC20
- Ethereum Improvement Proposals (EIPs): proposals for upgrading protcols for development or even l1 features.
- ERC20 Token Standard: how to create tokens.
- ERC20: token deployed in a chain using the standard. Many examples, some with erc77 because is better.
- For creating a token We should build a contract that has some functions declared for token standards.

### Explore Open Zeppelin
Leverage pre-deployed, audited, and ready-to-go contracts to simplify the creation process of your ERC20 token or many others. https://www.openzeppelin.com/solidity-contracts
Also solmate is very good for inheriting contracts.