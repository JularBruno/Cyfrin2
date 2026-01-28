## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

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

# Hola

### For installing
Project is inside git so created with `--no-git` flag and installing requires the same
```forge install openzeppelin/openzeppelin-contracts --no-git```

### wow Very cool mekrle trees

https://updraft.cyfrin.io/courses/advanced-foundry/merkle-airdrop/merkle-proofs

Merkle Trees are just cryptographic data structured like a tree, having data as leaves, that generate a unique hash.
We will use openzepelin merkletrees.sol and it will update the hash on array push.
It will generate root and leaf to use Merkle Proof to check if leaf is in the tree.
This can verify state changes in smart contracts or rollups, and be used to validate some keys data, and also