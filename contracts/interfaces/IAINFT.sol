// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC4906.sol";

interface IAINFT is IERC4906 {
    
    ///@dev check if the given spender is approved or owner of given tokenId.
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
    
    ///@dev check if the corresponding AINFT contract is cloned or not.
    function isCloned() external view returns (bool);

    ///@dev get the current version of given tokenId.
    function tokenURICurrentVersion(uint256 tokenId) external view returns (uint256);

    ///@dev get the tokenURI of given tokenId and uriVersion.
    function tokenURIByVersion(uint256 tokenId, uint256 uriVersion) external view returns (string memory);
    
    ///@dev update with newTokenURI for the given tokenId and increment the uriVersion.
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) external returns (bool);
    
    ///@dev delete the current tokenURI and rollback tokenURI to previous version. If the tokenId hasn't updated before, it reverts
    function rollbackTokenURI(uint256 tokenId) external returns (bool);
}