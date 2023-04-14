// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "./interfaces/IAINFT721.sol";

/**
 *@dev AINFT721 contract
 */
contract AINFT721 is
    ERC721,
    Pausable,
    AccessControl,
    ERC721Burnable,
    IAINFT721
{
    using Strings for uint256;
    using Address for address;
    struct MetadataContainer {
        address updater;
        string metadataURI;
    }
    bool public immutable IS_CLONED;
    IERC721 public immutable ORIGIN_NFT;
    address public PAYMENT_PLUGIN;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private baseURI;
    uint256 public totalMinted = 0;
    mapping(bytes32 => MetadataContainer) private _metadataStorage; // keccak256(bytes(tokenId, <DELIMETER>, version)) => MetadataContainer
    mapping(uint256 => uint256) private _tokenURICurrentVersion; // tokenId => tokenURIVersion

    constructor(string memory name_, string memory symbol_, bool isCloned_, address originNFT_) ERC721(name_, symbol_) {
        //FIXME(jakepyo): If AINFT721 is created/cloned by AINFTFactory, tx.origin should be set corresponding roles.
        // However under the discussion, if AINFTFactory should be removed, tx.origin should be replaced with msg.sender. 
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(PAUSER_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, tx.origin);
        ORIGIN_NFT = IERC721(originNFT_);
        IS_CLONED = isCloned_;
        require((address(ORIGIN_NFT) == address(0) && !IS_CLONED) ||
                (address(ORIGIN_NFT) != address(0) && IS_CLONED), 
                "If AINFT721 is created first time, the originNFT_ should be set zero address. \
                \n If AINFT721 is cloned by already existing ERC721 contract, the originNFT_ should be set existing contract address.");
    }

    modifier Cloned() {
        require(IS_CLONED, "Only cloned contract can execute.");
        _;
    }

    modifier NotCloned() {
        require(!IS_CLONED, "Only created contract can execute.");
        _;
    }

    function isCloned() public view returns (bool) {
        return IS_CLONED;
    }
    
    function mintFromOriginInstance(
        uint256 tokenId_
    ) public Cloned {
        require(!_exists(tokenId_), "The tokenId_ is already minted or cloned");
        require(_msgSender() == ORIGIN_NFT.ownerOf(tokenId_), "The sender should be the holder of origin NFT.");
        _safeMint(_msgSender(), tokenId_);
        totalMinted += 1;
    }
    
    function mintBulkFromOriginInstance(
        uint256[] calldata tokenIds_,
        address[] calldata recipients_
    ) public Cloned {
        for (uint i = 0; i < tokenIds_.length; i++) {
            require(!_exists(tokenIds_[i]), "The tokenId_ is already minted or cloned");
            require(recipients_[i] == ORIGIN_NFT.ownerOf(tokenIds_[i]), "The sender should be the holder of origin NFT.");
            _safeMint(recipients_[i], tokenIds_[i]);
        }
        totalMinted += tokenIds_.length;
    }

    function setPaymentContract(address paymentPlugin_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_msgSender() == tx.origin && _msgSender() != address(0), "Only EOA can set payment contract.");
        require(paymentPlugin_.isContract(), "The paymentPlugin_ should be a contract address.");
        PAYMENT_PLUGIN = paymentPlugin_;
    }

    /**
     * @dev See {IAINFT721}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControl,
            ERC721,
            IERC165
        )
        returns (bool)
    {
        return 
            interfaceId == type(IAINFT721).interfaceId ||
            super.supportsInterface(interfaceId);
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
        NotCloned
    {
        _safeMint(to, tokenId);
        totalMinted += 1;
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
        if (totalMinted == 1) emit MetadataUpdate(0);
        else if (totalMinted > 1) emit BatchMetadataUpdate(0, totalMinted - 1);
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
             PAYMENT_PLUGIN == _msgSender() ||
             PAYMENT_PLUGIN == address(0)),
            "AINFT721::updateTokenURI() - only payment contract can call this funciton. Or, you can call this function directly if PAYMENT_PLUGIN is unset."
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
             PAYMENT_PLUGIN == _msgSender() ||
             PAYMENT_PLUGIN == address(0)),
            "AINFT721::rollbackTokenURI() - only payment contract can call this function. Or, you can call this function directly if PAYMENT_PLUGIN is unset."
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
