#!/bin/bash

# anvil --port 8545 --chain-id 31337

# anvil --port 8546 --chain-id 31338

source .env

echo "Building contracts..."
forge build

### Compile and deploy the Rebase Token contract

# forge create src/RebaseToken.sol:RebaseToken --rpc-url ${CHAIN_A_RPC_URL}   --private-key ${PRIVATE_KEY}   --broadcast | awk '/Deployed to:/ {print $3}'
# 0x5FbDB2315678afecb367f032d93F642f64180aa3

echo "Deploying RebaseToken on Chain A..."
CHAINA_REBASE_TOKEN_ADDRESS=$(forge create src/RebaseToken.sol:RebaseToken \
 --rpc-url ${CHAIN_A_RPC_URL} \
 --private-key ${PRIVATE_KEY} \
 --broadcast | awk '/Deployed to:/ {print $3}')

echo "ZKsync rebase token address: $CHAINA_REBASE_TOKEN_ADDRESS"

### Compile and deploy the pool contract

# locally is required to deploy mock contracts
echo "Deploying mock contracts..."
MOCK_ROUTER=$(forge create test/mocks/MockRouter.sol:MockRouter \
  --rpc-url ${CHAIN_A_RPC_URL} \
  --private-key ${PRIVATE_KEY} \
  --broadcast | awk '/Deployed to:/ {print $3}')

MOCK_RNM_PROXY=$(forge create test/mocks/MockRNMProxy.sol:MockRNMProxy \
  --rpc-url ${CHAIN_A_RPC_URL} \
  --private-key ${PRIVATE_KEY} \
  --broadcast | awk '/Deployed to:/ {print $3}')

echo "Compiling and deploying the pool contract on ZKsync..."
CHAINA_POOL_ADDRESS=$(forge create src/RebaseTokenPool.sol:RebaseTokenPool --rpc-url ${CHAIN_A_RPC_URL} --private-key ${PRIVATE_KEY} --constructor-args ${CHAINA_REBASE_TOKEN_ADDRESS} [] ${MOCK_RNM_PROXY} ${MOCK_ROUTER} | awk '/Deployed to:/ {print $3}')
echo "Pool address: $CHAINA_POOL_ADDRESS"

forge create src/RebaseTokenPool.sol:RebaseTokenPool --rpc-url ${CHAIN_A_RPC_URL} --private-key ${PRIVATE_KEY} --constructor-args ${CHAINA_REBASE_TOKEN_ADDRESS} [] ${ZKSYNC_RNM_PROXY_ADDRESS} ${ZKSYNC_ROUTER} | awk '/Deployed to:/ {print $3}'