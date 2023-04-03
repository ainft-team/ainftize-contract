// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "./interfaces/IERC4906.sol";
import "./interfaces/IAINFT.sol";

/**
 *@dev AINFT721 contract
 */
contract AINFT721 is
    ERC721Enumerable,
    Pausable,
    AccessControl,
    ERC721Burnable,
    IERC4906,
    IAINFT
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    struct MetadataContainer {
        address updater;
        string metadataURI;
    }
    bool public immutable IS_CLONED;
    IERC721 public immutable ORIGIN_NFT;
    address public PAYMENT_PLUGIN;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;
    string private baseURI;
    mapping(bytes32 => MetadataContainer) private _metadataStorage; // keccak256(bytes(tokenId, <DELIMETER>, version)) => MetadataContainer
    mapping(uint256 => uint256) private _tokenURICurrentVersion; // tokenId => tokenURIVersion

    constructor(string memory name_, string memory symbol_, bool isCloned_, address originNFT_) ERC721(name_, symbol_) {
        if (isCloned_) {
            //FIXME: need to use tx.origin?
            _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
            _grantRole(PAUSER_ROLE, tx.origin);
            _grantRole(MINTER_ROLE, tx.origin);

            
        } else {
            //FIXME: the originNFT contract address should not be ROLED
            _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
            _grantRole(PAUSER_ROLE, tx.origin);
            _grantRole(MINTER_ROLE, tx.origin);
        }
        ORIGIN_NFT = IERC721(originNFT_);
        IS_CLONED = isCloned_;
        require((address(ORIGIN_NFT) == address(0) && !IS_CLONED) ||
                (address(ORIGIN_NFT) != address(0) && IS_CLONED), 
                "If AINFT721 is created first time, the originNFT_ should not be SET. \
                \n If AINFT721 is cloned by something, the originNFT_ should be SET.");
    }

    modifier Cloned () {
        require(IS_CLONED, "Only cloned contract can execute.");
        _;
    }
    
    function mintFromOriginInstance(
        uint256 tokenId_
    ) public Cloned {
        require(!_exists(tokenId_), "The tokenId_ is already minted or cloned");
        address originOwner = ORIGIN_NFT.ownerOf(tokenId_);
        require(_msgSender() == originOwner, "The sender should be the holder of origin NFT.");
        _safeMint(_msgSender(), tokenId_);

    }
    
    function mintFromOriginInstanceOnBehalf(
        uint256[] calldata tokenIds_,
        address[] calldata recipients_
    ) public Cloned onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < tokenIds_.length; i++) {
            require(!_exists(tokenIds_[i]), "The tokenId_ is already minted or cloned");
            require(recipients_[i] == ORIGIN_NFT.ownerOf(tokenIds_[i]), "The sender should be the holder of origin NFT.");
            _safeMint(recipients_[i], tokenIds_[i]);
        }
    }

    function setPaymentContract(address paymentPlugin_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_msgSender() == tx.origin && _msgSender() != address(0), "Only EOA can set payment contract.");
        PAYMENT_PLUGIN = paymentPlugin_;
    }

    /**
     * @dev See {IERC4906}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControl,
            ERC721Enumerable,
            ERC721,
            IERC165
        )
        returns (bool)
    {
        // IERC4906 interface added
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(
        address to,
        uint256 tokenId
    )
        public
        onlyRole(MINTER_ROLE)
    {
        //FIXME: If you use ERC721Enumerable, the original design is mint it enumerically.
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721, ERC721Enumerable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual override(ERC721) {
        super._requireMinted(tokenId);
    }

    function isApprovedOrOwner(
        address spender, 
        uint256 tokenId
    ) public view virtual returns (bool)
    {
        return super._isApprovedOrOwner(spender, tokenId);
    }

    function burn(uint256 tokenId) public override(ERC721Burnable) {
        super.burn(tokenId);
    }

    ////
    // URI & METADATA RELATED FUNCTIONS
    ////

    function _baseURI() internal view override(ERC721) returns (string memory) {
        return baseURI;
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        _requireMinted(tokenId);
        uint256 currentVersion = _tokenURICurrentVersion[tokenId];

        return tokenURIByVersion(tokenId, currentVersion);
    }

    /**
     * @dev Returns the key for the metadata storage.
     * @return The metadata storage key.
     */
    function _metadataStorageKey(
        uint256 tokenId,
        uint256 version
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId.toString(), "AINFT delimeter", version));
    }

    /**
     * @dev The metadata storage is a mapping of token ID to metadata.
     * @return The metadata storage.
     */
    function metadataStorageByVersion(
        uint256 tokenId,
        uint256 version
    ) public view returns (MetadataContainer memory) {
    
        bytes32 key = _metadataStorageKey(tokenId, version);
        return _metadataStorage[key];
    }

    function tokenURICurrentVersion(
        uint256 tokenId
    ) public view returns (uint256) {
        _requireMinted(tokenId);
        return _tokenURICurrentVersion[tokenId];
    }

    function tokenURIByVersion(
        uint256 tokenId,
        uint256 uriVersion
    ) public view returns (string memory) {
        _requireMinted(tokenId);
        if (uriVersion == 0) {
            return string(abi.encodePacked(baseURI, tokenId.toString()));
        } else {
            MetadataContainer memory metadata = metadataStorageByVersion(tokenId, uriVersion);
            return metadata.metadataURI;
        }
    }

    function setBaseURI(
        string memory newBaseURI
    ) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        require(
            bytes(newBaseURI).length > 0,
            "AINFT721::setBaseURI() - Empty newBaseURI"
        );
        require(
            keccak256(bytes(newBaseURI)) != keccak256(bytes(baseURI)),
            "AINFT721::setBaseURI() - Same newBaseURI as baseURI"
        );

        baseURI = newBaseURI;
        //TODO: emit BatchMetadataUpdate(start, end). Consider after updateTokenURI() calls.
        return true;
    }

    /**
     * @dev version up & upload the metadata. You should call this function externally when the token is updated.
     */
    function updateTokenURI(
        uint256 tokenId,
        string memory newTokenURI
    ) external returns (bool) {
        require(
            (isApprovedOrOwner(tx.origin, tokenId) ||
             PAYMENT_PLUGIN == _msgSender()),
            "AINFT721::updateTokenURI() - only payment contract can call this funciton."
        );
        _requireMinted(tokenId);

        uint256 updatedVersion = ++_tokenURICurrentVersion[tokenId];
        bytes32 metadataKey = _metadataStorageKey(tokenId, updatedVersion);
        _metadataStorage[metadataKey] = MetadataContainer({
            updater: _msgSender(),
            metadataURI: newTokenURI
        });

        emit MetadataUpdate(tokenId);
        return true;
    }

    /**
     * @dev if you've ever updated the metadata more than once, rollback the metadata to the previous one and return true.
     * if its metadata has not been updated yet or failed to update, return false
     */
    function rollbackTokenURI(uint256 tokenId) external returns (bool) {
        require(
            (isApprovedOrOwner(tx.origin, tokenId) ||
             PAYMENT_PLUGIN == _msgSender()),
            "AINFT721::rollbackTokenURI() - only payment contract can call this function."
        );
        _requireMinted(tokenId);

        uint256 currentVersion = _tokenURICurrentVersion[tokenId];
        if (currentVersion == 0) return false;
        else {
            //delete the currentVersion of _metadataStorage
            bytes32 currentMetadataKey = _metadataStorageKey(
                tokenId,
                currentVersion
            );
            delete _metadataStorage[currentMetadataKey];

            //rollback the version
            _tokenURICurrentVersion[tokenId]--;
            emit MetadataUpdate(tokenId);
            return true;
        }
    }

    ////
    ////
}
