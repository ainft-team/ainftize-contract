// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//TODO: implement the function inside
interface IAINFT {
    
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) external returns (bool);
    
    ///@dev delete the recent tokenURI and rollback tokenURI to previous one. If the tokenId is origin, it reverts
    function rollbackTokenURI(uint256 tokenId) external returns (bool);

    function getOriginTokenURI(uint256 tokenId) external view returns (string memory);
    function getRecentTokenURI(uint256 tokenId) external view returns (string memory);
    function getCertainTokenURI(uint256 tokenId, uint256 uriVersion) external view returns (string memory);

}