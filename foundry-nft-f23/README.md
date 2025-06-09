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

## Develop an NFT Collection
### What is an NFT

- ERC-721 non fungible token, another standard like ERC20
- ERC20 are a mapping between an adress and what it holds
- ERC-721 unique token id with unique owners and unique URI
- URI: URL and URN, identifier of  a resource
- IPFS URI can store an image and you can point to NFT URI, this holds nft offchain - omg so much gas
- Is best to have on chain to hold the authenticity of the NFT

### Introduction to IPFS

- IPFS creaetes own node to host storage, you can make it more accessible in more nodes
- Deploy app to ipfs
    - Downloaded appimage that can be executed
    - Imported some file 
    - Now the file can be opened with ipfs:// a browser with ipfs companion, making it visible
    - We have and can see our node


### Test the NFTs smart contract

```
chisel
Welcome to Chisel! Type `!help` to show available commands.
➜ string memory cat = "cat";
➜ string memory dog = "dog";
➜ cat
Type: string
├ UTF-8: cat
├ Hex (Memory):
├─ Length ([0x00:0x20]): 0x0000000000000000000000000000000000000000000000000000000000000003
├─ Contents ([0x20:..]): 0x6361740000000000000000000000000000000000000000000000000000000000
├ Hex (Tuple Encoded):
├─ Pointer ([0x00:0x20]): 0x0000000000000000000000000000000000000000000000000000000000000020
├─ Length ([0x20:0x40]): 0x0000000000000000000000000000000000000000000000000000000000000003
└─ Contents ([0x40:..]): 0x6361740000000000000000000000000000000000000000000000000000000000
➜ bytes memory encodedCat = abi.encodePacked(cat);
➜ encodedCat
Type: dynamic bytes
├ Hex (Memory):
├─ Length ([0x00:0x20]): 0x0000000000000000000000000000000000000000000000000000000000000003
├─ Contents ([0x20:..]): 0x6361740000000000000000000000000000000000000000000000000000000000
├ Hex (Tuple Encoded):
├─ Pointer ([0x00:0x20]): 0x0000000000000000000000000000000000000000000000000000000000000020
├─ Length ([0x20:0x40]): 0x0000000000000000000000000000000000000000000000000000000000000003
└─ Contents ([0x40:..]): 0x6361740000000000000000000000000000000000000000000000000000000000
➜ bytes32 catHash = keccak256(encodedCat)
➜ catHash
Type: bytes32
└ Data: 0x52763589e772702fa7977a28b3cfb6ca534f0208a2b2d55f7558af664eac478a
```

#### Deploy your NFTs on the testnet

Could be deployed to anvil but used Makefile deploy
Added env with SEPOLIA_RPC_URL and PRIVATE_KEY
Makefile includes source env
Sepolia was too gas expensive for me to deploy I runned it in anvil 
```
forge script script/DeployBasicNft.s.sol:DeployBasicNft --rpc-url 127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```
broadcast run latest 
ffi = true

#### IPFS and Pinata vs HTTP vs on chain SVGs
Host nft on more descentralized because ipfs node could be the only one pined. Other people could pin it. It is poular because is cheap.

Pinata is more descentralized. Upload, get hash.
File should be updated both in ipfs and pinata.

#### What is an SVG?

Since we want an svg as a uri, you can decode it
```
base64 -i
```
turns svg into code

### Encoding SVGs to be stored onchain

IMAGE URI, encoded to save gas

data:image/svg+xml;base64, + `base64 -i`

Token uri describes everything in nft

openzepelin has a tool to convert json object into json object uri 

#### Create the deployment script
```base64 -i ./img/example.svg ```


### Deploy and interact using Anvil
```
forge script script/DeployMoodNft.s.sol:DeployMoodNft --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

cast send <CONTRACT_ADDRESS> 0x5FbDB2315678afecb367f032d93F642f64180aa3 "mintNft()" --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --rpc-url http://localhost:8545
```
On metamask import nft on gochaintestnet, contractAddress, id 0 import

Flip mood
```
cast send 0x5FbDB2315678afecb367f032d93F642f64180aa3 "flipMood(uint256)" 0 --private-key ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --
rpc-url http://localhost:8545
```

Some checks and tests
```
cast call 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 "ownerOf(uint256)(address)" 0 --rpc-url http://localhost:8545
cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "tokenURI(uint256)(string)" 0 --rpc-url http://localhost:8545
```

Cast send
- Sends a real transaction
- Changes contract state 
- Requires a private key and ETH
Cast Call
- Calls a view or pure function on a contract
- Does not cost gas
- Does not change state

### Advanced EVM - Opcodes, calling, etc

abi.encode abi.encodePacked

- evm overview, compiles abi and bin(binary)
- transaction fields on contract deployment, is special since To: empty and Data: contract init code and bytecode 
- bytecode, just as a dictionary for evm machines, made with opcode 
- actually encodePacked encodes to bytecode without restrictions

### Advanced EVM - Encoding

Transaction fields on function call Data: what to send to To address
Can be seen on etherscan Input data field, also can be seen in hex, bytes (evm knows which function to call)
Useful for sending directly function calls, requires
- abi
- Contract address
