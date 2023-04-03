// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "./AINFT721.sol";

contract AINFTFactory is Ownable {
    address private _clonedAINFTContract = address(0);
    address private _createdAINFTContract = address(0);

    constructor() Ownable() {}

    function cloneERC721(
        ERC721 originalNFT_,
        string memory newName_,
        string memory newSymbol_
    ) public returns (address) {
        address originalNFTAddr = address(originalNFT_);
        require(originalNFTAddr != address(0), ""); 
        
        address ret = _cloneInstanceAINFT721(originalNFT_, newName_, newSymbol_); // msg.sender is admin
        require(ret != address(0), "Cloned contract is successfully created");
        _clonedAINFTContract = ret;
        return ret;
    }

    function createAINFT721(
        string memory name_,
        string memory symbol_
    ) public returns (address) {
        address ret = _createInstanceAINFT721(name_, symbol_); //msg.sender is admin
        require(ret != address(0), "Created contract is successfully created");
        _createdAINFTContract = ret;
        return ret;
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

    function getClonedAINFTContract() public view returns (address) {
        return _clonedAINFTContract;
    }

    function getCreatedAINFTContract() public view returns (address) {
        return _createdAINFTContract;
    }

}
