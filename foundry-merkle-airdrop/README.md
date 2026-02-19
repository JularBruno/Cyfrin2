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

## For installing
Project is inside git so created with `--no-git` flag and installing requires the same
```forge install openzeppelin/openzeppelin-contracts --no-git```

### wow Very cool mekrle trees

https://updraft.cyfrin.io/courses/advanced-foundry/merkle-airdrop/merkle-proofs

Merkle Trees are just cryptographic data structured like a tree, having data as leaves, that generate a unique hash.
We will use openzepelin merkletrees.sol and it will update the hash on array push.
It will generate root and leaf to use Merkle Proof to check if leaf is in the tree.
This can verify state changes in smart contracts or rollups, and is used mostly to validate some keys data, very efficient hashing.
tldr: Merkle proof prove data is in merkle tree

### Base Airdrop Contract
WE 

### Already Claimed Check

Key Security Concepts and Best Practices Reinforced
This lesson highlights several crucial concepts for secure smart contract development:

Multiple Claims Vulnerability: A frequent oversight in airdrop or reward distribution contracts. Always ensure that a user cannot claim their entitlement more than once.

State Tracking: Using mapping(address => bool) is a straightforward and gas-efficient method to track whether an address has performed a specific state-changing action.

Reentrancy Attacks: One of the most notorious smart contract vulnerabilities. It occurs when an external call allows an attacker to re-enter the calling function before its initial execution completes critical state changes.

Checks-Effects-Interactions (CEI) Pattern: A vital security design pattern to mitigate reentrancy and other unexpected behaviors.

Checks: Perform all validations (e.g., permissions, input validity, existing state) first.

Effects: Make all internal state changes to your contract.

Interactions: Execute calls to other contracts or transfer value.
Adhering to this order significantly reduces the attack surface for reentrancy.

Custom Errors: Introduced in Solidity 0.8.4, custom errors (e.g., error MerkleAirdrop_AlreadyClaimed();) provide a more gas-efficient and descriptive way to handle error conditions
