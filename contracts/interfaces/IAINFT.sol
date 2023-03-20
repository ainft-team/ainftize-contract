// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

//TODO: implement the function inside
interface IAINFT {

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
    function tokenURICurrentVersion(uint256 tokenId) external view returns (uint256);
    function setBaseURI(string memory newBaseURI) external returns (bool);

    ///@dev fetch the tokenURI of tokenId by certain version
    function tokenURIByVersion(uint256 tokenId, uint256 uriVersion) external view returns (string memory);
    
    ///@dev update the new token URI and version up
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) external returns (bool);
    
    ///@dev delete the recent tokenURI and rollback tokenURI to previous one. If the tokenId is origin, it reverts
    function rollbackTokenURI(uint256 tokenId) external returns (bool);


}