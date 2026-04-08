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

## Introduction

Blockchains derive their power from three core properties: they are decentralized, transparent, and immutable. Smart contracts, as programs running on a blockchain, inherit these characteristics. Immutability, in particular, is a foundational feature that ensures a contract's logic, once deployed, cannot be altered. This creates a trustless environment where users can verify the code and be certain its rules will never change.

This immutability acts as a double-edged sword. While it guarantees a single source of truth and removes the need to trust a central party, it also presents significant challenges.

To address these limitations, the web3 ecosystem developed the concept of upgradeable smart contracts, providing a way to modify logic while preserving a contract's state and address.

To grasp how a contract can be "upgraded" despite being immutable, you must distinguish between its logic and its state.

- Logic: This is the contract's code—the functions, rules, and operations you write in Solidity. Once deployed to the blockchain, this logic is unchangeable.
- State: This is the data stored within the contract's variables, such as user balances, ownership records, or configuration settings. The contract's logic is specifically designed to read and modify this state

##### Three Methods for Managing Contract Changes
1. The Parameterization Method
2. The Social Migration Method
3. The Proxy Pattern: The proxy pattern is the most common and powerful method for implementing true upgradeability. This architectural pattern cleverly separates a contract's state and address from its logic.

When a user calls a function on the Proxy Contract, the proxy uses a low-level EVM function called delegatecall to forward the call to the current Implementation Contract. The delegatecall function is special: it executes the code from the Implementation Contract, but it does so within the context of the Proxy Contract's storage. This means the logic from the implementation acts directly on the state stored in the proxy.

To perform an upgrade, developers simply deploy a new Implementation Contract (V2) with the updated logic. They then execute a single transaction on the Proxy Contract to tell it to point to the address of this new implementation.

##### Security Considerations for Proxy Patterns

- Storage Clashes: A delegatecall applies the implementation's logic to the proxy's storage layout. Solidity assigns storage variables to "slots" based on their order of declaration in the code, not by their names. If a V2 implementation changes the order of variables, declares a new variable before an existing one, or changes a variable's type, it will misinterpret the data stored in the proxy's slots. This leads to state corruption, where the contract reads and writes to the wrong variables, with catastrophic results.

- The Golden Rule of Proxy Storage: When upgrading, you can only append new state variables. You must never reorder, remove, or change the type of existing state variables.

- Function Selector Clashes: A function selector is the first four bytes of the cryptographic hash of a function's signature. Because this identifier is so short, it is possible for two different functions (e.g., transfer(address,uint256) and destroy(string)) to have the exact same 4-byte selector. This is known as a function selector clash.


Common Proxy Patterns and Their Solutions
To mitigate these risks, several standardized proxy patterns have emerged.

- Transparent Proxy Pattern: This pattern solves function selector clashes by adding routing logic to the proxy. It inspects the address of the caller (msg.sender). If the caller is the designated admin, the call is handled by the proxy's own logic. If the caller is any other user, the call is delegated to the implementation.

- UUPS (Universal Upgradeable Proxy Standard - EIP-1822): This pattern,  moves the upgrade logic itself out of the proxy and into the implementation contract. This makes the proxy contract smaller, cheaper to deploy, and more universal. It also solves selector clashes by design, as the Solidity compiler will not allow two functions with the same selector to exist within the same contract (the implementation).

- Diamond Proxy Pattern (EIP-2535): This is a highly advanced, modular pattern. Instead of pointing to a single implementation, a Diamond proxy can delegate calls to multiple implementation contracts, known as "facets." A central mapping within the proxy routes each function selector to its corresponding facet. This allows for granular upgrades (updating only one part of a complex system) and helps developers manage contracts that would otherwise exceed the maximum contract size limit.

**A Final Word of Caution**
Upgradeable smart contracts are a powerful tool, but they should not be the default choice. They introduce centralization, as a privileged address must be able to authorize upgrades. They also add significant complexity and new attack surfaces. The primary goal of web3 development should always be to progress towards decentralized, immutable systems. 

## Overview of the EIP-1967

##### EIP-1967 Proxy
This SmallProxy example contains a lot of Yul. Yul is a sort of in-line Assembly that allows you to write really low-level code. Like anything low-level it comes with increased risk and severity of mistakes, it's good to avoid using Yul as often as you can justify.

The need to regularly utilize storage to reference things in implementation (specifically the implementation address) led to the desire for EIP-1967: Standard Proxy Storage Slots. This proposal would allocate standardized slots in storage specifically for use by proxies.

**SmallProxy.sol deployed on Remix**
By passing an argument to getDataToTransact we're provided the encoded call data necessary to set our valueAtStorageSlotZero to 777. Remember, sending a transaction to our proxy with this call data should update the storage in the proxy.


Then the flow in Remix:

Deploy ImplementationA → copy address
Deploy SmallProxy
Call setImplementation on SmallProxy with ImplementationA's address
Call getDataToTransact(777) on SmallProxy → copy the bytes output
Paste that bytes into the low-level calldata box at the bottom of SmallProxy → hit Transact
Call readStorage → should return 777

Next, deploy ImplementationB and then call setImplementation on SmallProxy, passing this new implementation address.
valueAtStorageSlotZero now reflects the new implementation logic of newValue + 2!

**This kind of power should also give you pause and make you consider the effects of trusting this degree of centrality to the protocol developers.**

Selector Clashes
One quick final note on function selector clashes which I'd mentioned earlier. In our example here, SmallProxy.sol only really has one function setImplementation, but if the implementation contract also had a function called setImplementation, it would be easy to see how this conflict could occur. 

## Using delegateCall

Contract B is very simple, it contains 3 storage variables which are set by the setVars function.

If we recall, storage acts kind of like an array and each storage variable is sequentially assigned a slot in storage, in the order in which the variable is declared in a contract.

In contract A we're doing much the same thing, the biggest different of course being that we're using delegateCall.

This works fundamentally similar to call. In the case of call we would be calling the setVars function on Contract B and this would update the storage on Contract B, as you would expect.

With delegateCall however, we're borrowing the logic from Contract B and referencing the storage of Contract A. This is entirely independent of what the variables are actually named.

Importantly, this behaviour, due to referencing storage slots directly, is independent of any naming conventions used for the variables themselves. In fact, if Contract A didn't have any of it's own declared variables at all, the appropriate storage slots would still be updated!

What if we changed the variable type of number in Contract A to a bool? If we then call delegateCall on Contract B, we'll see it's set our storage slot to true. The bool type detects our input as true, with 0 being the only acceptable input for false.




