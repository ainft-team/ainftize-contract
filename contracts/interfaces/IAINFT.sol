// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//TODO: implement the function inside
interface IAINFT {

    ///@dev fetch the tokenURI of tokenId by certain version
    function tokenURIByVersion(uint256 tokenId, uint256 uriVersion) external view returns (string memory);
    
    ///@dev update the new token URI and version up
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) external returns (bool);
    
    ///@dev delete the recent tokenURI and rollback tokenURI to previous one. If the tokenId is origin, it reverts
    function rollbackTokenURI(uint256 tokenId) external returns (bool);


}