# ainftize-contract

*Upgradeable contract template is not completely implemented yet. Do not use it.*


## Call graphs of the core contracts

There are three core contracts in this project: `AINFT721.sol`, `AINFTFactory.sol`, `AINPayment.sol`. Each contract serves the following purpose:

- `AINFT721.sol`: This contract is the ERC721-extended contract that supports some update schemes related to AINFTs. The main feature is that token holders have permissions to update and rollback their metadata. History is kept in both contract and AIN blockchain. 
- `AINFTFactory.sol`: This contract is the factory contract that is used to create new AINFT721 or clone AINFT721 from existing ERC721 contract. It is a standard ERC721 contract with some additional functions to support the AINFTize protocol.
- `AINPayment.sol`: This contract is the payment contract that is used to pay the creator of the NFT. It is a standard ERC20 contract with some additional functions to support the AINFTize protocol.

The following call graphs show the interactions between these three contracts.


![Call graph for Overall AINFT](docs/callgraph/AINFT.svg)


## Prerequisite
- node.js
- yarn
- npx

## Installation
```
> yarn install
```





## Compilation
```
> npx hardhat compile
```

## Deployment(Not Implemented yet)
```
> npx hardhat run scripts/deploy.ts
```

## Test
```
# for integration test
> npx hardhat test test/integrationTest.ts
```
