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

```shell
 forge install dmfxyz/murky --no-git
```

When you first try to run a script that writes files using vm.writeFile(), you might encounter an error like: "path script/target/input.json is not allowed to be accessed for write operations." To resolve this, you must grant file system permissions in your foundry.toml file. Add the fs_permissions key:

```shell
forge script script/GenerateInput.s.sol:GenerateInput
```

Logic Overview (Conceptual - actual code can be adapted from murky examples or course repositories):
Process Each Leaf Entry
Leaf Hash Calculation
Generate Merkle Root and Proofs
Construct and Write output.json

Running the MakeMerkle.s.sol script:

```shell
forge script script/MakeMerkle.s.sol:MerkleScript
```

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

### Deployment Script

Install foundry-devops (Optional but Recommended for Multi-Chain)

For handling potential differences in deployment mechanisms across chains

```shellforge install cyfrin/foundry-devops --no-git ```

The setUp() function in your test file is responsible for initializing the state before each test runs. We'll update it to use our deployment script for standard EVM environments and fall back to manual deployment for ZKsync chains

// Constants previously defined in the test, ensure they align with script values if consistency is desired.
    // bytes32 ROOT = 0x...; // Should match s_merkleRoot from the script
    // uint256 AMOUNT_TO_CLAIM = 25 * 1e18;
    // uint256 AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4; // Should match s_amountToTransfer from the script

### Adding Signature Verification

Optimizing Merkle Airdrop Claims: Authorization and Gas Fee Management

The primary issue with this implementation is its permissiveness regarding who can initiate a claim. As written, any address can call the claim function on behalf of any other account that is legitimately part of the Merkle tree. For instance, an arbitrary user could trigger a claim for a well-known address, like Patrick Collins's. While Patrick would indeed receive the tokens, this action would occur without his direct initiation or consent for that specific transaction.

This raises concerns: a user might receive an airdrop—and any associated tax liabilities or simply unwanted tokens—without having explicitly agreed to that particular claim event at that moment.

A Simpler Approach: Recipient-Initiated Claims and Its Limitations

A straightforward way to ensure the recipient's consent and direct involvement is to modify the claim function. By removing the account parameter and consistently using msg.sender to identify the claimant, we achieve two things:

Direct Consent: Only the rightful owner of the address (the one controlling the private key for msg.sender) can initiate the claim for their tokens.

Recipient Pays Gas: The account calling claim (i.e., msg.sender) would inherently be responsible for paying the transaction's gas fees.

##### Advanced Solution: Enabling Gasless Claims with Digital Signatures
A more sophisticated and flexible solution involves leveraging digital signatures. This method allows an account to explicitly consent to receiving their airdrop while still permitting another party to submit the transaction and pay the associated gas fees. This effectively makes the claim "gasless" from the recipient's perspective.

Here's how the workflow would operate:

Recipient's Intent (User A): User A is eligible for an airdrop and wishes to claim it. However, they want User B (the Payer) to submit the actual blockchain transaction and cover the gas costs.

Message Creation (User A): User A constructs a "message." This message essentially states their authorization, for example: "I, User A, authorize the claim of my airdrop entitlement of X amount. This claim can be submitted by User B (or, depending on the message design, by any authorized party)."

Signing the Message (User A): User A uses their private key to cryptographically sign this message. The resulting signature is a verifiable proof that User A, and only User A, authorized the contents of that specific message.

Information Transfer: User A provides the original message components (e.g., their address, the claim amount) and the generated signature to User B.

Transaction Submission (User B): User B calls the claim function on the MerkleAirdrop contract. They will pass the following parameters:

account: User A's address (the intended recipient).

amount: The airdrop amount User A is eligible for.

merkleProof: User A's Merkle proof, verifying their inclusion in the airdrop.

signature: The digital signature provided by User A.

Smart Contract Verification: The claim function must be updated to perform these crucial verification steps:

Confirm that account (User A) has not already claimed their airdrop.

Validate the merkleProof against the contract's i_merkleRoot for the given account and amount.

Critically, verify that the signature is a valid cryptographic signature originating from account (User A) for a message authorizing this specific claim operation. This involves reconstructing the message within the smart contract and using cryptographic functions to check the signature's validity against User A's public key (derived from their address).

Token Transfer and Gas Payment: If all verifications pass, the airdrop tokens are transferred to account (User A). The gas fees for this transaction are paid by msg.sender (User B).

Benefits of Implementing Signature-Based Airdrop Claims
This signature-based approach offers several compelling advantages:

Explicit Consent: The recipient (User A) directly and verifiably authorizes the claim by signing a message specific to that action. This eliminates ambiguity about their willingness to receive the tokens at that time.

Gas Abstraction: It allows a third party (User B) to pay the transaction fees. This enables "gasless" claims for the end-user, potentially improving user experience and adoption, especially for users less familiar with gas mechanics or those with insufficient native currency for fees.

Enhanced Security: The smart contract can cryptographically confirm that the intended recipient genuinely authorized the claim. This prevents unauthorized claims made on behalf of others, even if the Merkle proof is valid.

### Understanding Ethereum Signatures: EIP-191 & EIP-712

This lesson delves into the essential Ethereum signature standards, EIP-191 and EIP-712. We'll explore how signatures are created, how they can be verified within smart contracts, and critically, how these standards enhance security by preventing replay attacks and improve the user experience by making signed data human-readable.

**The Need for EIP-191 and EIP-712: Solving Unreadable Messages and Replay Attacks** 

Before the advent of EIP-191 and EIP-712, interacting with decentralized applications often involved signing messages that appeared as long, inscrutable hexadecimal strings in wallets like MetaMask. For instance, a user might be presented with a "Sign Message" prompt showing data like 0x1257deb74be69e9c464250992e09f18b478fb8fa247dcb.... This "unreadable nonsense" made it extremely difficult, and risky, for users to ascertain what they were actually approving. There was no easy way to verify if the data was legitimate or malicious.

This highlighted two critical needs:

- Readability: A method was required to present data for signing in a clear, understandable format.

- Replay Protection: A mechanism was needed to prevent a signature, once created, from being maliciously reused in a different context (a replay attack).

**Basic Signature Verification: The Fundamentals**

Before diving into the EIP standards, let's understand the basic process of signature verification in Ethereum. The core concept involves taking a message, hashing it, and then using the signature (comprising v, r, and s components) along with this hash to recover the signer's Ethereum address. This recovered address is then compared against an expected signer's address.

**The Problem with Simple Signatures and the Genesis of EIP-191**

The simple signature verification method described above has a significant flaw: it lacks context. A signature created for one specific purpose or smart contract could potentially be valid for another if only the raw message hash is signed. This ambiguity opens the door for replay attacks, where a malicious actor could take a signature intended for contract A and use it to authorize an action on contract B, if contract B expects a similarly structured message.

**EIP-191: The Signed Data Standard**
EIP-191 was introduced to standardize the format for data that is signed off-chain and intended for verification, often within smart contracts. Its primary goal is to ensure that signed data cannot be misinterpreted as a regular Ethereum transaction, thereby preventing a class of replay attacks.

For a smart contract to verify an EIP-191 signature, it must reconstruct this exact byte sequence (0x19 || version || version_data || data_to_sign), hash it using keccak256, and then use this resulting hash with the provided v, r, and s components in the ecrecover function.

In this getSigner191 function, we define the prefix (0x19), eip191Version (0x00), and intendedValidatorAddress (which is the address of the current contract, address(this)). The applicationSpecificData is our message. These components are concatenated using abi.encodePacked and then hashed with keccak256. The resulting hash is used with ecrecover.

While EIP-191 standardizes the signing format and adds a layer of domain separation (e.g., with the validator address in version 0x00), version 0x00 itself doesn't inherently solve the problem of displaying complex <data to sign> in a human-readable way in wallets. This is where EIP-712 comes into play.

**EIP-712: Typed Structured Data Hashing and Signing**
EIP-712 builds upon EIP-191, to achieve two primary objectives:

Human-Readable Signatures: Enable wallets to display complex, structured data in an understandable format to users before signing.

Robust Replay Protection: Provide strong protection against replay attacks by incorporating domain-specific information into the signature.

The EIP-712 signing format, under EIP-191 version 0x01, is:
0x19 0x01 <domainSeparator> <hashStruct(message)>

0x19 0x01: The EIP-191 prefix (0x19) followed by the EIP-191 version byte (0x01), indicating that the signed data adheres to the EIP-712 structured data standard.

<domainSeparator>: This is the "version specific data" for EIP-191 version 0x01. It's a bytes32 hash that is unique to the specific application domain. This makes a signature valid only for this particular domain (e.g., a specific DApp, contract, chain, and version of the signing structure).
The domainSeparator is calculated as hashStruct(eip712Domain). The eip712Domain is a struct typically defined as:

struct EIP712Domain {
    string  name;                // Name of the DApp or protocol
    string  version;             // Version of the signing domain (e.g., "1", "2")
    uint256 chainId;             // EIP-155 chain ID (e.g., 1 for Ethereum mainnet)
    address verifyingContract;   // Address of the contract that will verify the signature
    bytes32 salt;                // Optional unique salt for further domain separation
}
The domainSeparator is the keccak256 hash of the ABI-encoded instance of this EIP712Domain struct. Crucially, including chainId and verifyingContract ensures that a signature created for one DApp on one chain cannot be replayed on another DApp or another chain.

<hashStruct(message)>: This is the "data to sign" part of the EIP-191 structure. It's a bytes32 hash representing the specific structured message the user is signing.
Its calculation involves two main parts: hashStruct(structData) = keccak256(typeHash || encodeData(structData)).

- typeHash: This is a keccak256 hash of the definition of the message's struct type. It includes the struct name and the names and types of its members, formatted as a string. For example, for a struct Message { uint256 amount; address to; }, the type string would be "Message(uint256 amount,address to)", and the typeHash would be keccak256("Message(uint256 amount,address to)").

- encodeData(structData): This is the ABI-encoded data of the struct instance itself. The EIP-712 specification details how different data types within the struct should be encoded before hashing. For Solidity, this typically involves abi.encode(...) where the first argument is the typeHash of the primary type, followed by the values of the struct members in their defined order.

The final bytes32 digest that is actually passed to ecrecover (or a safer alternative) for EIP-712 compliant signatures is:
digest = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, hashStruct(message)))

##### Leveraging OpenZeppelin for Robust EIP-712 Implementation
Manually implementing EIP-712 hashing and signature verification can be complex and error-prone. It is highly recommended to use well-audited libraries like those provided by OpenZeppelin. Specifically, EIP712.sol and ECDSA.sol are invaluable.

### ECDSA Signatures

Unveiling ECDSA: Understanding Digital Signatures and v, r, s Values
Elliptic Curve Digital Signature Algorithm (ECDSA) and its characteristic v, r, s values are fundamental components in the world of blockchain and Web3 security.

Decoding ECDSA: Elliptic Curve Digital Signature Algorithm
ECDSA stands for Elliptic Curve Digital Signature Algorithm. As the name suggests, it is an algorithm built upon the principles of Elliptic Curve Cryptography (ECC). Its primary functions are crucial for digital security and identity

**The Role of Signatures in Blockchain Authentication**
In blockchain technology, particularly in systems like Ethereum, digital signatures serve as a critical means of authentication. They provide verifiable proof that a transaction or message genuinely originates from the claimed sender and has not been tampered with.

The entire process is underpinned by Public Key Cryptography (PKC), which uses asymmetric encryption (different keys for encrypting/signing and decrypting/verifying).

The Unbreakable Lock: Security of ECDSA Private Keys

**How ECDSA Works: A Closer Look at the Algorithm**
The (v, r, s) Signature Components:
An ECDSA signature consists of three components: v, r, and s. These are essentially derived from coordinates of a point on the chosen elliptic curve (secp256k1 in Ethereum's case). Each such point represents a unique signature.

An analogy helps illustrate this: Imagine you are given the number 96,673 and told it's the product of two large prime numbers, x and y. Finding x and y from 96,673 is very difficult (factorization). However, if you were given x and y, multiplying them to get 96,673 is easy. Similarly, it's easy to compute pubKey from p and G, but extremely hard to compute p given only pubKey and G. This one-way property is the bedrock of ECDSA's security.

#### Validating Authenticity: The ECDSA Signature Verification Process

Ethereum's ecrecover Precompile:
Ethereum provides a built-in function (a precompile, meaning it's implemented at a lower level for efficiency) called ecrecover. The function ecrecover(hashedMessage, v, r, s) performs signature verification.

Instead of just returning true/false, if the signature (v, r, s) is valid for the hashedMessage, ecrecover returns the Ethereum address of the signer.

This is extremely useful for smart contracts, as it allows them to verify signatures on-chain and reliably retrieve the address of the account that signed a particular piece of data.

Securely Using ecrecover in Ethereum Smart Contracts
While ecrecover is a powerful tool, using it directly in smart contracts requires careful consideration to avoid potential security vulnerabilities.
1. Signature Malleability
2. ecrecover Returns Zero Address for Invalid Signatures

### Deploying Smart Contracts: Ethereum vs. zkSync and the Hidden Transaction Difference

Deploying Smart Contracts: Ethereum vs. zkSync and the Hidden Transaction Difference

To enable zkSync deployment, install the specific Foundry fork. This grants access to the foundry-zksync extension: foundryup-zksync
To interact with the testnets, we require Remote Procedure Call (RPC) URLs. Using a provider like Alchemy, generate endpoints for both Sepolia (Ethereum) and zkSync Sepolia.

Create a .env file in your root directory to store these endpoints securely:

We will use the default Counter.sol template generated by forge init. While the Solidity code is standard, the deployment command for zkSync requires specific flags to ensure the bytecode is compiled and formatted correctly for the zkEVM.

--zksync: This is the critical switch. It instructs Foundry to use the zksolc compiler rather than the standard solc, ensuring compatibility with the zkSync VM.

##### The "Sneaky Difference": Analyzing Transaction Types

Open Etherscan (or Blockscout) for Sepolia and paste your Ethereum deployment hash. Navigate to the detailed 
view of the transaction.
Ethereum used the standard EIP-1559 (Type 2) envelope.

Open the zkSync Sepolia Explorer and paste your zkSync deployment hash.
zkSync used a specialized Type 113 envelope.

This distinction is not merely cosmetic. Transaction Type 113 allows zkSync to support native features such as Account Abstraction and paymasters directly at the protocol level. 

## Transaction Types

Shared Transaction Types: Ethereum and zkSync
Ethereum and zkSync share several fundamental transaction types. These form the bedrock of how interactions are structured on both L1 and L2.

- Transaction Type 0 (Legacy Transactions / 0x0)
Type 0, also known as Legacy Transactions or identified by the prefix 0x0, represents the original transaction format used on Ethereum. This was the standard before the formal introduction of distinct, typed transactions. It embodies the initial method for structuring and processing transactions on the network.
The --legacy flag highlighted here directly indicates the use of a Type 0 transaction.

- Transaction Type 1 (Optional Access Lists / 0x01 / EIP-2930)
Transaction Type 1, denoted as 0x01, was introduced by EIP-2930, titled "Optional Access Lists."
Type 1 transactions maintain the same fields as legacy (Type 0) transactions but introduce a significant addition: an accessList parameter. This parameter is an array containing addresses and storage keys that the transaction plans to access during its execution. The main benefit of including an access list is the potential for gas savings on cross-contract calls.

- Transaction Type 2 (EIP-1559 Transactions / 0x02)
Transaction Type 2, or 0x02, was introduced by EIP-1559 as part of Ethereum's "London" hard fork. 
Type 2 transactions include new parameters:

maxPriorityFeePerGas: The maximum tip the sender is willing to pay per unit of gas.

maxFeePerGas: The absolute maximum total fee (baseFee + priorityFee) the sender is willing to pay per unit of gas.

- Transaction Type 3 (Blob Transactions / 0x03 / EIP-4844 / Proto-Danksharding)

This EIP represents an initial, significant step towards scaling Ethereum, particularly for rollups like zkSync. It introduces a new, more cost-effective way for Layer 2 solutions to submit data to Layer 1 via "blobs."

Key features of Type 3 transactions include:

A separate fee market specifically for blob data, distinct from regular transaction gas fees.

Additional fields on top of those found in Type 2 transactions:

max_fee_per_blob_gas: The maximum fee the sender is willing to pay per unit of gas for the blob data.

blob_versioned_hashes: A list of versioned hashes corresponding to the data blobs carried by the transaction.

A crucial aspect of the blob fee mechanism is that this fee is deducted from the sender's account and burned before the transaction itself is executed. This means that if the transaction fails for any reason during execution, the blob fee is non-refundable.

##### zkSync-Specific Transaction Types

- Type 113 (EIP-712 Transactions / 0x71)
Type 113, or 0x71, transactions on zkSync utilize the EIP-712 standard, "Ethereum typed structured data hashing and signing.

On zkSync, Type 113 transactions are pivotal for accessing advanced, zkSync-specific features such as native Account Abstraction (AA) and Paymasters.

A critical requirement for developers is that smart contracts **must** be deployed on zkSync using a Type 113 (0x71) transaction. 

In addition to standard Ethereum transaction fields, Type 113 transactions on zkSync include several custom fields:

- Type 255 (Priority Transactions / 0xff)

Type 255, or 0xff, transactions on zkSync are known as "Priority Transactions." Their primary purpose is to enable the sending of transactions directly from Ethereum L1 to the zkSync L2 network.

Common use cases include:
Depositing assets from Ethereum L1 to zkSync L2.
Triggering L2 smart contract calls or functions from an L1 transaction.

Priority transactions bridge the two layers, ensuring that L1-initiated actions can be reliably processed and reflected on the zkSync rollup.

## Blob Transactions

#### EIP-4844: Revolutionizing Layer 2 Scaling with Blob Transactions

This pivotal upgrade brought forth a new transaction type: Blob Transactions (Type 3). The primary objective of these transactions is to drastically lower the costs for Layer 2 (L2) rollups to post their data to the Ethereum Layer 1 (L1) mainnet, ultimately making transactions on L2 solutions significantly cheaper for end-users.

###### Understanding Blob Transactions: The Core Innovation

To appreciate the impact of EIP-4844, it's essential to distinguish between traditional Ethereum transactions and the new blob-carrying transactions:

- Normal Transactions (Type 2 - EIP-1559): In standard Ethereum transactions, all associated data, including input data (known as calldata), is permanently stored on the Ethereum blockchain. Every Ethereum node is required to store this data indefinitely.

- Blob Transactions (Type 3 - EIP-4844): These transactions introduce a novel component: "blobs." Blobs are large, additional chunks of data carried by the transaction. Crucially, this blob data is not stored permanently by the L1 execution layer (the Ethereum Virtual Machine - EVM). Instead, it's guaranteed to be available on the consensus layer for a temporary period—approximately 18 days (or 4096 epochs)—after which it is pruned (deleted) by the nodes. The core transaction details (such as sender, recipient, value, etc.) remain permanently stored on-chain.

**What are Blobs?**
The term "blob" is a common shorthand for Binary Large Object. In the context of EIP-4844:

Blobs are substantial, fixed-size data packets, each precisely 128 Kilobytes (KiB). This size is composed of 4096 individual fields, each 32 bytes long.

They provide a dedicated and more economical data space for L2 rollups to post their transaction batches, compared to the previously used, more expensive calldata.

##### The Problem Solved: Why Blob Transactions Were Needed
Ethereum's L1 has historically faced high transaction fees due to its limited block space and substantial demand. This is a direct consequence of the blockchain trilemma, which posits a trade-off between scalability, security, and decentralization.

**The Pre-Blob Bottleneck:**
Before EIP-4844, rollups posted their compressed transaction batches to L1 using the calldata field of a standard L1 transaction. This approach was a significant cost driver because:

Calldata consumes valuable and limited L1 block space.

This calldata had to be stored permanently by all L1 nodes.

The requirement for permanent storage of large data volumes increases hardware and computational demands on node operators, which directly translates into higher gas fees for all users

##### How EIP-4844 Works: The Mechanics of Blobs
EIP-4844, or Proto-Danksharding, provides an elegant solution by allowing rollups to post their data as blobs instead of relying solely on calldata.

- Temporary Data Availability: Blobs are designed for short-term data availability. After the defined window (around 18 days), this data is pruned from the consensus layer.
- A New, Cheaper Data Market: Blobs introduce their own independent fee market, distinct from the gas market for computation and standard calldata
- Verification Without EVM Access: A cornerstone of EIP-4844's design is that the L1 can verify the availability and integrity of blob data without the EVM needing to directly access or process the contents of the blobs themselves. In fact, the EVM cannot directly access blob data. This efficient verification is achieved through:
KZG Commitments: For each blob, a KZG (Kate-Zaverucha-Goldberg) commitment is generated. This is a type of polynomial commitment, serving as a small, fixed-size cryptographic proof (akin to a hash) that represents the entire blob.

## Understanding Type 113 Transactions: An Introduction to Account Abstraction

We are now bridging the gap between our previous discussions on EIP-712 signatures and standard transaction types to introduce one of the most powerful paradigms in Web3: Account Abstraction.

#### What is Account Abstraction?
At its core, Account Abstraction (AA) is the shift from holding user assets in Externally Owned Accounts (EOAs) to holding them in smart contracts.

In a traditional setup, users utilize standard wallets (like a basic MetaMask account) controlled strictly by a public-private key pair. With Account Abstraction, the goal is to decouple the relationship between the key pair and the account, effectively making user accounts fully programmable smart contracts.

**Ethereum Account Types**
On the Ethereum mainnet, the network distinguishes between two distinct types of accounts:

Externally Owned Accounts (EOAs):

- These are controlled by a private key.
- Constraint: A user must initiate and sign every transaction manually.
- Constraint: They have limited functionality; you cannot program arbitrary logic (rules) directly into an EOA.

Contract Accounts:
- These are smart contracts deployed to the network.
- Benefit: They can contain arbitrary logic and code.
- Constraint: They cannot initiate transactions on their own; they must be triggered by an EOA.

ZKsync Native Account Abstraction
ZKsync Era fundamentally changes this dynamic by integrating Account Abstraction natively into the protocol.They have the programmable logic of a smart contract but retain the ability to initiate transactions just like an EOA.

## Implementing EIP-712 Signature Verification for Gasless Airdrop Claims

#### The Off-Chain Signing Process
With the smart contract ready, the user (or a frontend application acting on their behalf) needs to perform these steps:

Determine Claim Details: Identify the user's account, the amount they are eligible for, and their merkleProof.

Calculate the Digest: The frontend application will call the getMessage(account, amount) view function on your deployed MerkleAirdrop contract (or replicate its exact EIP-712 hashing logic client-side using libraries like ethers.js or viem). This produces the digest to be signed.

Request Signature: The frontend will use a wallet provider (like MetaMask) to request the user to sign this typed data. Wallets that support EIP-712 (e.g., MetaMask via eth_signTypedData_v4) will display the structured AirdropClaim data (account and amount) and the domain information (contract name, version) to the user in a readable format.

User Approves: The user reviews the information and approves the signing request in their wallet. The wallet then returns the signature components: v, r, and s.

Submit to Relayer: The frontend sends the account, amount, merkleProof, and the signature (v, r, s) to a relayer service.

Relayer Executes Claim: The relayer calls the MerkleAirdrop.claim(account, amount, merkleProof, v, r, s) function on the smart contract, paying the gas fee for the transaction.

## Test On ZKsync (Optional)

```shell
foundryup-zksync
forge build --zksync
forge test --zksync -vv
```

## Creating A Signature
##### Preparing Your Foundry and Anvil Environment

```shell
foundryup
anvil
make deploy
```

Compiler run successful!
Script ran successfully.

== Return ==
0: contract MerkleAirdrop 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
1: contract BagelToken 0x5FbDB2315678afecb367f032d93F642f64180aa3

##### Crafting the Data: Generating the Message Hash
```shell
cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getMessage(address,uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 25000000000000000000 --rpc-url http://localhost:8545
```
0x39430e4990aa8a1f7d056d9a5f611eb27f8280425efbf03634690a02f26b957a

##### Signing the Message Hash: Authorizing the Claim

```shell
cast wallet sign --no-hash 0x39430e4990aa8a1f7d056d9a5f611eb27f8280425efbf03634690a02f26b957a --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

0x12e145324b60cd4d302bfad59f72946d45ffad8b9fd608e672fd7f02029de7c438cfa0b8251ea803f361522da811406d441df04ee99c3dc7d65f8550e12be2ca1c

##### Deconstructing the Signature: Understanding v, r, and s

// script/interact.s.sol
To execute this script, you would populate v_sig, r_sig, and s_sig (and the proof array) with the actual values derived from your signature generation process and Merkle tree construction, then run it using forge script.

