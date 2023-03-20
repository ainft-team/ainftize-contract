// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

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

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdCounter;
    string private baseURI;
    mapping(bytes32 => MetadataContainer) private _metadataStorage; // keccak256(bytes(tokenId, <DELIMETER>, version)) => MetadataContainer
    mapping(uint256 => uint256) private _tokenURICurrentVersion; // tokenId => tokenURIVersion

    constructor() ERC721("Name", "SYMBOL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
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
        address to
    )
        public
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
            (isApprovedOrOwner(_msgSender(), tokenId) ||
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
            (_msgSender() == ownerOf(tokenId)) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
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

    ////
    ////
}
