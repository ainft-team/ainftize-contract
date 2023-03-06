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
        bytes32 current;
        bytes32 prev;
        bytes32 origin;
        address updater;
        uint256 updatedAt;
        string metadataURI;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    CountersUpgradeable.Counter private _tokenIdCounter;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    string public baseURI;
    mapping(bytes32 => MetadataContainer) private metadataStorage; // keccak256(bytes32(tokenId, version))
    mapping(uint256 => uint256) public tokenURICurrentVersion; // tokenId: tokenURIVersion

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("AINFT721 Template", "AFT");
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

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual override {
        super._requireMinted(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        //TODO
        _requireMinted(tokenId);
        return getRecentTokenURI(tokenId);        
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC721EnumerableUpgradeable, ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    
    function setBaseURI(string memory newBaseURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        require(bytes(newBaseURI).length > 0, "AINFT721::setBaseURI() - Empty newBaseURI");
        require(keccak256(bytes(newBaseURI)) != keccak256(bytes(baseURI)), "AINFT721::setBaseURI() - Same newBaseURI as baseURI");

        baseURI = newBaseURI;
        return true;
    }

    /**
     * Override the IAINFT.sol
     */
    function setTokenURIByUser(uint256 tokenId, string memory newTokenURI)
        external 
        returns (bool)
    {
        require(_msgSender() == ownerOf(tokenId), "AINFT721::setTokenURIByUser() - not owner of tokenId");
        super._setTokenURI(tokenId, newTokenURI);
        
        emit MetadataUpdate(tokenId);
        return true;
    }

    function setTokenURIByOwner(uint256 tokenId, string memory newTokenURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (bool)
    {
        super._setTokenURI(tokenId, newTokenURI);
        
        emit MetadataUpdate(tokenId);
        return true;
    }

    function getOriginTokenURI(uint256 tokenId) 
        external 
        view 
        returns (string memory)
    {
        uint256 currentVersion = tokenURICurrentVersion[tokenId];
        if (currentVersion == 0) return _baseURI();
        else return metadataStorage[keccak256(bytes(
            string(abi.encodePacked(tokenId.toString(), 
                                    "AINFT delimeter", 
                                    "0"
                                    )
                )
            ))].metadataURI;
    }

    function getPreviousTokenURI(uint256 tokenId) 
        external 
        view 
        returns (string memory)
    {
        uint256 currentVersion = tokenURICurrentVersion[tokenId];
        if (currentVersion == 0) return "";
        else return metadataStorage[keccak256(bytes(
            string(abi.encodePacked(tokenId.toString(), 
                                    "AINFT delimeter", 
                                    (currentVersion - 1).toString()
                                    )
                )
            ))].metadataURI;
    }

    function getRecentTokenURI(uint256 tokenId)
        public
        override
        view
        returns (string memory) 
    {
        uint256 currentVersion = tokenURICurrentVersion[tokenId];
        if (currentVersion == 0) return string(abi.encodePacked(_baseURI(), "/", tokenId.toString()));
        else return metadataStorage[keccak256(bytes(
            string(abi.encodePacked(tokenId.toString(), 
                                    "AINFT delimeter", 
                                    currentVersion.toString()
                                    )
                )
            ))].metadataURI;
    }


}