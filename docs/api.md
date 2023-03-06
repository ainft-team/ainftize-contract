# Solidity API

## AINClient

### unlockTime

```solidity
uint256 unlockTime
```

### owner

```solidity
address payable owner
```

### Withdrawal

```solidity
event Withdrawal(uint256 amount, uint256 when)
```

### constructor

```solidity
constructor(uint256 _unlockTime) public payable
```

### withdraw

```solidity
function withdraw() public
```

## AINFT721

### PAUSER_ROLE

```solidity
bytes32 PAUSER_ROLE
```

### MINTER_ROLE

```solidity
bytes32 MINTER_ROLE
```

### UPGRADER_ROLE

```solidity
bytes32 UPGRADER_ROLE
```

### baseURI

```solidity
string baseURI
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize() public
```

### _baseURI

```solidity
function _baseURI() internal view returns (string)
```

_Base URI for computing {tokenURI}. If set, the resulting URI for each
token will be the concatenation of the `baseURI` and the `tokenId`. Empty
by default, can be overridden in child contracts._

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### safeMint

```solidity
function safeMint(address to, string uri) public
```

### _beforeTokenTransfer

```solidity
function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal
```

### _authorizeUpgrade

```solidity
function _authorizeUpgrade(address newImplementation) internal
```

_Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
{upgradeTo} and {upgradeToAndCall}.

Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.

```solidity
function _authorizeUpgrade(address) internal override onlyOwner {}
```_

### _burn

```solidity
function _burn(uint256 tokenId) internal
```

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view returns (string)
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

### setBaseURI

```solidity
function setBaseURI(string newBaseURI) public returns (bool)
```

