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

### Merkle Tree Script

##### Understanding Merkle Trees and Proofs for Airdrop Testing
To effectively test the claim function of our MerkleAirdrop.sol contract, which internally uses MerkleProof.verify from OpenZeppelin, our tests require several key components:

A valid Merkle root: This is the single hash stored in the smart contract that represents the entirety of the airdrop distribution data.

A list of addresses and their corresponding airdrop amounts: This data forms the "leaves" of the Merkle tree.

A Merkle proof for each specific address/amount pair: This proof allows an individual user to demonstrate that their address and amount are part of the Merkle tree, without revealing the entire dataset.

##### Introducing murky for Merkle Tree Generation:
To generate these Merkle roots and proofs within our Foundry project, we'll utilize the murky library by dmfxyz (available on GitHub: https://github.com/dmfxyz/murky). This library provides tools for constructing Merkle trees and generating proofs directly within Foundry scripts.

Data Structure for Merkle Tree Generation:
We will use two JSON files to manage the Merkle tree data: input.json for the raw data and output.json for the generated tree information including proofs.

input.json (Raw Airdrop Data):
This file serves as the input for our Merkle tree generation script. It defines the structure and values for each leaf node.

types: An array specifying the data types for each component of a leaf node (e.g., ["address", "uint"] for an address and its corresponding airdrop amount).

count: The total number of leaf nodes (i.e., airdrop recipients).

values: An object where keys are zero-based indices. Each value is an object representing the components of a leaf. For types ["address", "uint"], the inner object would have keys "0" for the address and "1" for the amount.

output.json (Generated Merkle Tree Data):
This file will be produced by our script after processing input.json. It contains the complete Merkle tree information, including the root and individual proofs. Each entry in the JSON array corresponds to a leaf.

inputs: The original data for the leaf (e.g., ["address_value", "amount_value"]).

proof: An array of bytes32 hashes representing the Merkle proof required to verify this leaf against the root.

root: The bytes32 Merkle root of the entire tree. This value will be the same for all entries.

leaf: The bytes32 hash of this specific leaf's data.

``` forge install dmfxyz/murky --no-git ```

When you first try to run a script that writes files using vm.writeFile(), you might encounter an error like: "path script/target/input.json is not allowed to be accessed for write operations." To resolve this, you must grant file system permissions in your foundry.toml file. Add the fs_permissions key:

``` forge script script/GenerateInput.s.sol:GenerateInput ```

Logic Overview (Conceptual - actual code can be adapted from murky examples or course repositories):
Process Each Leaf Entry
Leaf Hash Calculation
Generate Merkle Root and Proofs
Construct and Write output.json

Running the MakeMerkle.s.sol script:

``` forge script script/MakeMerkle.s.sol:MerkleScript ```

### Writing The Tests

Integrating Off-Chain Merkle Tree Data
Our Merkle Airdrop relies on a Merkle tree generated off-chain. The ROOT of this tree is stored in the contract, and users provide PROOFs to claim. For testing, we need to ensure our test user is part of this tree.

Generate Test User Address: After writing the initial setUp function, run forge test -vvv. This will execute setUp, and you can use console.log(user); within setUp to print the generated user address.

Update Merkle Tree Generation Scripts:

You'll typically have scripts (e.g., script/GenerateInput.s.sol using Foundry scripting, or external scripts) that create a list of whitelisted addresses and amounts (e.g., in an input.json file).

Add the user address obtained in the previous step to this whitelist in your input generation script, associating it with AMOUNT_TO_CLAIM.

Run your script to regenerate the input file (e.g., forge script script/GenerateInput.s.sol).

Generate New Merkle Tree and Proofs:

Run the script that processes your input file to build the Merkle tree and output the new ROOT and individual proofs (e.g., script/MakeMerkle.s.sol, which might output an output.json).

Update Test File with New Merkle Data:

ROOT: Copy the new Merkle ROOT from your output.json (or equivalent output) and update the ROOT state variable in MerkleAirdropTest.t.sol.

PROOF: Locate the Merkle proof specific to your user address in output.json. This will be an array of bytes32 hashes.

Copy these hash values into the proofOne, proofTwo, etc., intermediate state variables you defined earlier.

Then, initialize the PROOF array:

// Inside MerkleAirdropTest, update these after generating the new Merkle tree
// Example values:
// ROOT = 0xNEW_ROOT_HASH_FROM_OUTPUT_JSON;
// proofOne = 0xPROOF_HASH_1_FOR_USER;
// proofTwo = 0xPROOF_HASH_2_FOR_USER;
​
// In setUp() or as part of state variable initialization:
// PROOF = [proofOne, proofTwo];
This method of using intermediate variables helps avoid potential type conversion errors when directly initializing the bytes32[] array.

Now, your setUp function will deploy the MerkleAirdrop contract with the correct ROOT that includes your test user.

