// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IERC4906Upgradeable.sol";
import "./interfaces/IAINFT.sol";

/**
 *@dev Proxy contract for AINFT721
 *@notice About design pattern, refer to https://github.com/OpenZeppelin/openzeppelin-labs/tree/master/upgradeability_using_inherited_storage
 */
contract AINFT721Upgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable,
    IERC4906Upgradeable,
    IAINFT
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using Strings for uint256;

    struct MetadataContainer {
        address updater;
        string metadataURI;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;
    string public baseURI;
    mapping(bytes32 => MetadataContainer) public metadataStorage; // keccak256(bytes32(tokenId, version))
    mapping(uint256 => uint256) public tokenURICurrentVersion; // tokenId: tokenURIVersion

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
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function safeMint(
        address to,
        string memory uri
    ) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    function logicVersion() external virtual returns (uint256) {
        return 1;
    }

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual override {
        super._requireMinted(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        //TODO
        _requireMinted(tokenId);
        return getRecentTokenURI(tokenId);
    }

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
        return super.supportsInterface(interfaceId);
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
        return true;
    }

    /**
     * Override the IAINFT.sol
     */

    function getMetadataStorageKey(
        uint256 tokenId,
        uint256 version
    ) public pure returns (bytes32) {
        
        return keccak256(
            bytes(
                string(
                    abi.encodePacked(tokenId.toString(), "AINFT delimeter", version.toString())
                    )
                )
        );
    }

    /**
     * @dev version up & upload the metadata
     */
    function updateTokenURI(
        uint256 tokenId,
        string memory newTokenURI
    ) external returns (bool) {
        require(
            (_msgSender() == ownerOf(tokenId)) ||
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AINFT721::updateTokenURI() - not owner of tokenId or contract owner"
        );

        uint256 updatedVersion = ++tokenURICurrentVersion[tokenId];
        bytes32 metadataKey = getMetadataStorageKey(tokenId, updatedVersion);
        metadataStorage[metadataKey] = MetadataContainer({
                                                updater: _msgSender(),
                                                metadataURI: newTokenURI
                                        });
        super._setTokenURI(tokenId, newTokenURI);
        emit MetadataUpdate(tokenId);
        return true;
    }

    /**
     * @dev if you've ever updated the metadata more than once, rollback the metadata to the previous one and return true.
     * if its metadata has not been updated yet or failed to update, return false
     */
    function _rollbackTokenURI(uint256 tokenId) internal returns (bool) {
        require(
            (_msgSender() == ownerOf(tokenId)) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AINFT721::rollbackTokenURI() - only contract owner or token holder can call this funciton."
        );
        uint256 currentVersion = tokenURICurrentVersion[tokenId];
        if (currentVersion == 0) return false;
        else {
            //delete the currentVersion of metadataStorage
            bytes32 currentMetadataKey = getMetadataStorageKey(tokenId, currentVersion);
            delete metadataStorage[currentMetadataKey];

            //rollback the version
            tokenURICurrentVersion[tokenId]--;
            return true;
        }
    }

    function rollbackTokenURI(uint256 tokenId) external returns (bool) {
        return _rollbackTokenURI(tokenId);
    }

    function getOriginTokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "/", tokenId.toString()));
    }

    function getRecentTokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        uint256 currentVersion = tokenURICurrentVersion[tokenId];
        if (currentVersion == 0) {
            return getOriginTokenURI(tokenId);
        } else {
            bytes32 metadataKey = getMetadataStorageKey(tokenId, currentVersion);
            return metadataStorage[metadataKey].metadataURI;
        }
    }

    function getCertainTokenURI(
        uint256 tokenId,
        uint256 uriVersion
    ) public view override returns (string memory) {

        if (uriVersion == 0) {
            return getOriginTokenURI(tokenId);
        } else {
            bytes32 metadataKey = getMetadataStorageKey(tokenId, uriVersion);
            return metadataStorage[metadataKey].metadataURI;
        }
    }
}
