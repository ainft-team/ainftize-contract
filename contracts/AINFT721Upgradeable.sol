// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./interfaces/IERC4906Upgradeable.sol";
import "./interfaces/IAINFT.sol";

/**
 *@dev Proxy contract for AINFT721
 *@notice About design pattern, refer to https://github.com/OpenZeppelin/openzeppelin-labs/tree/master/upgradeability_using_inherited_storage
 */
contract AINFT721Upgradeable is
    Initializable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable,
    IERC4906Upgradeable,
    IAINFT
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    struct MetadataContainer {
        address updater;
        string metadataURI;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;
    string private baseURI;
    mapping(bytes32 => MetadataContainer) private _metadataStorage; // keccak256(bytes(tokenId, <DELIMETER>, version)) => MetadataContainer
    mapping(uint256 => uint256) private _tokenURICurrentVersion; // tokenId => tokenURIVersion

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    /**
     * @dev See {IERC4906Upgradeable}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControlUpgradeable,
            ERC721EnumerableUpgradeable,
            ERC721Upgradeable,
            IERC165Upgradeable
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
        address to
    )
        public
        // string memory uri
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _tokenIdCounter.current();
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
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _isApprovedOrOwner(
        address spender, 
        uint256 tokenId
    ) internal view virtual override(ERC721Upgradeable) returns (bool)
    {
        return super._isApprovedOrOwner(spender, tokenId);
    }
    

    ////
    // UPGRADEABLE RELATED FUNCTIONS
    ////

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    function logicVersion() external pure virtual returns (uint256) {
        return 1;
    }

    ////
    ////

    function burn(uint256 tokenId) public override(ERC721BurnableUpgradeable) {
        super.burn(tokenId);
    }

    ////
    // URI & METADATA RELATED FUNCTIONS
    ////

    function _baseURI() internal view override(ERC721Upgradeable) returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual override(ERC721Upgradeable) {
        super._requireMinted(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        _requireMinted(tokenId);
        uint256 currentVersion = _tokenURICurrentVersion[tokenId];

        return tokenURIByVersion(tokenId, currentVersion);
    }

    function _metadataStorageKey(
        uint256 tokenId,
        uint256 version
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenId.toString(), "AINFT delimeter", version));
    }
    
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
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
    ) public returns (bool) {
        require(
            (_isApprovedOrOwner(_msgSender(), tokenId) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender())),
            "AINFT721::updateTokenURI() - not owner of tokenId or contract owner"
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
    function rollbackTokenURI(uint256 tokenId) public returns (bool) {
        require(
            (_isApprovedOrOwner(_msgSender(), tokenId) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender())), 
            "AINFT721::rollbackTokenURI() - only contract owner or token holder can call this funciton."
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
}
