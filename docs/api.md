# Solidity API

## AINFT721

_AINFT721 contract_

### MetadataContainer

```solidity
struct MetadataContainer {
  address updater;
  string metadataURI;
}
```

### IS_CLONED

```solidity
bool IS_CLONED
```

### ORIGIN_NFT

```solidity
contract IERC721 ORIGIN_NFT
```

### PAYMENT_PLUGIN

```solidity
address PAYMENT_PLUGIN
```

### PAUSER_ROLE

```solidity
bytes32 PAUSER_ROLE
```

### MINTER_ROLE

```solidity
bytes32 MINTER_ROLE
```

### totalMinted

```solidity
uint256 totalMinted
```

### constructor

```solidity
constructor(string name_, string symbol_, bool isCloned_, address originNFT_) public
```

### Cloned

```solidity
modifier Cloned()
```

### NotCloned

```solidity
modifier NotCloned()
```

### isCloned

```solidity
function isCloned() public view returns (bool)
```

_check if the corresponding AINFT contract is cloned or not._

### mintFromOriginInstance

```solidity
function mintFromOriginInstance(uint256 tokenId_) public
```

### mintBulkFromOriginInstance

```solidity
function mintBulkFromOriginInstance(uint256[] tokenIds_, address[] recipients_) public
```

### setPaymentContract

```solidity
function setPaymentContract(address paymentPlugin_) public
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

_See {IAINFT721}._

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
function safeMint(address to, uint256 tokenId) public
```

### _requireMinted

```solidity
function _requireMinted(uint256 tokenId) internal view virtual
```

_Reverts if the `tokenId` has not been minted yet._

### isApprovedOrOwner

```solidity
function isApprovedOrOwner(address spender, uint256 tokenId) public view virtual returns (bool)
```

_check if the given spender is approved or owner of given tokenId._

### burn

```solidity
function burn(uint256 tokenId) public
```

_Burns `tokenId`. See {ERC721-_burn}.

Requirements:

- The caller must own `tokenId` or be an approved operator._

### _baseURI

```solidity
function _baseURI() internal view returns (string)
```

_Base URI for computing {tokenURI}. If set, the resulting URI for each
token will be the concatenation of the `baseURI` and the `tokenId`. Empty
by default, can be overridden in child contracts._

### tokenURI

```solidity
function tokenURI(uint256 tokenId) public view returns (string)
```

_See {IERC721Metadata-tokenURI}._

### _metadataStorageKey

```solidity
function _metadataStorageKey(uint256 tokenId, uint256 version) internal pure returns (bytes32)
```

_Returns the key for the metadata storage._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The metadata storage key. |

### metadataStorageByVersion

```solidity
function metadataStorageByVersion(uint256 tokenId, uint256 version) public view returns (struct AINFT721.MetadataContainer)
```

_The metadata storage is a mapping of token ID to metadata._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct AINFT721.MetadataContainer | The metadata storage. |

### tokenURICurrentVersion

```solidity
function tokenURICurrentVersion(uint256 tokenId) public view returns (uint256)
```

_get the current version of given tokenId._

### tokenURIByVersion

```solidity
function tokenURIByVersion(uint256 tokenId, uint256 uriVersion) public view returns (string)
```

_get the tokenURI of given tokenId and uriVersion._

### setBaseURI

```solidity
function setBaseURI(string newBaseURI) public returns (bool)
```

### updateTokenURI

```solidity
function updateTokenURI(uint256 tokenId, string newTokenURI) external returns (bool)
```

_version up & upload the metadata. You should call this function externally when the token is updated._

### rollbackTokenURI

```solidity
function rollbackTokenURI(uint256 tokenId) external returns (bool)
```

_if you've ever updated the metadata more than once, rollback the metadata to the previous one and return true.
if its metadata has not been updated yet or failed to update, return false_

## AINFTFactory

### CloneAINFT721

```solidity
event CloneAINFT721(address originalNFT, address clonedAINFT)
```

### CreateAINFT721

```solidity
event CreateAINFT721(address createdAINFT)
```

### constructor

```solidity
constructor() public
```

### cloneERC721

```solidity
function cloneERC721(contract ERC721 originalNFT_, string newName_, string newSymbol_) public returns (address)
```

### createAINFT721

```solidity
function createAINFT721(string name_, string symbol_) public returns (address)
```

### _cloneInstanceAINFT721

```solidity
function _cloneInstanceAINFT721(contract ERC721 originalNFT_, string name_, string symbol_) internal returns (address)
```

### _createInstanceAINFT721

```solidity
function _createInstanceAINFT721(string name_, string symbol_) internal returns (address)
```

## IAINFT

### isApprovedOrOwner

```solidity
function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool)
```

_check if the given spender is approved or owner of given tokenId._

### isCloned

```solidity
function isCloned() external view returns (bool)
```

_check if the corresponding AINFT contract is cloned or not._

### tokenURICurrentVersion

```solidity
function tokenURICurrentVersion(uint256 tokenId) external view returns (uint256)
```

_get the current version of given tokenId._

### tokenURIByVersion

```solidity
function tokenURIByVersion(uint256 tokenId, uint256 uriVersion) external view returns (string)
```

_get the tokenURI of given tokenId and uriVersion._

### updateTokenURI

```solidity
function updateTokenURI(uint256 tokenId, string newTokenURI) external returns (bool)
```

_update with newTokenURI for the given tokenId and increment the uriVersion._

### rollbackTokenURI

```solidity
function rollbackTokenURI(uint256 tokenId) external returns (bool)
```

_delete the current tokenURI and rollback tokenURI to previous version. If the tokenId hasn't updated before, it reverts_

## IAINFT721

## IERC4906

https://eips.ethereum.org/EIPS/eip-4906#backwards-compatibility

### MetadataUpdate

```solidity
event MetadataUpdate(uint256 _tokenId)
```

_This event emits when the metadata of a token is changed.
So that the third-party platforms such as NFT market could
timely update the images and related attributes of the NFT._

### BatchMetadataUpdate

```solidity
event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId)
```

_This event emits when the metadata of a range of tokens is changed.
So that the third-party platforms such as NFT market could
timely update the images and related attributes of the NFTs._

## AINPayment

AINPayment address should be registered PAYMENT_ROLE in AINFT721.sol

### _ain

```solidity
contract IERC20 _ain
```

### _ainft

```solidity
contract IAINFT _ainft
```

### _price

```solidity
uint256[2] _price
```

### constructor

```solidity
constructor(address ainft, address ain) public
```

### setPrice

```solidity
function setPrice(uint256[2] price) external
```

### _pay

```solidity
function _pay(uint256 amount) internal returns (bool)
```

Before executing _pay(), _ain.approve(address(this), type(uint256).max) should be called by user.

_Pay AIN to AINPayment contract_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount | uint256 | Amount of AIN to pay |

### executeUpdate

```solidity
function executeUpdate(uint256 tokenId, string newTokenURI) external returns (bool)
```

### executeRollback

```solidity
function executeRollback(uint256 tokenId) external returns (bool)
```

### withdraw

```solidity
function withdraw(uint256 amount) public returns (bool)
```

### withdrawAll

```solidity
function withdrawAll() public returns (bool)
```

### destruct

```solidity
function destruct(string areYouSure) external payable
```

## ERC20_

### constructor

```solidity
constructor(string name_, string symbol_, uint256 totalSupply_) public
```

## ERC721Mintable_

### constructor

```solidity
constructor(string name_, string symbol_) public
```

### mint

```solidity
function mint(address to, uint256 tokenId) public
```

