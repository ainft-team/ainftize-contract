// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "./AINFT721.sol";

contract AINFTFactory is Ownable {
    event CloneAINFT721(address indexed originalNFT, address indexed clonedAINFT);
    event CreateAINFT721(address indexed createdAINFT);

    constructor() Ownable() {}

    function cloneERC721(
        ERC721 originalNFT_,
        string memory newName_,
        string memory newSymbol_
    ) public returns (address) {
        require(address(originalNFT_) != address(0), ""); 
        address clonedAINFTAddr = _cloneInstanceAINFT721(originalNFT_, newName_, newSymbol_); // msg.sender is admin
        require(clonedAINFTAddr != address(0), "Cloned contract is successfully created");
        emit CloneAINFT721(address(originalNFT_), clonedAINFTAddr);
        return clonedAINFTAddr;
    }

    function createAINFT721(
        string memory name_,
        string memory symbol_
    ) public returns (address) {
        address createdAINFTAddr = _createInstanceAINFT721(name_, symbol_); //msg.sender is admin
        require(createdAINFTAddr != address(0), "Created contract is successfully created");
        emit CreateAINFT721(createdAINFTAddr);
        return createdAINFTAddr;
    }

    function _cloneInstanceAINFT721(
        ERC721 originalNFT_,
        string memory name_,
        string memory symbol_
    ) internal returns (address) {
        AINFT721 ainft721 = new AINFT721(name_, symbol_, true, address(originalNFT_));
        return address(ainft721);
    }

    function _createInstanceAINFT721(
        string memory name_,
        string memory symbol_
    ) internal returns (address) {
        AINFT721 ainft721 = new AINFT721(name_, symbol_, false, address(0));
        return address(ainft721);
    }
}
