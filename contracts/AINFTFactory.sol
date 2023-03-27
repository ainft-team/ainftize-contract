// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

import "./AINFT721.sol";

contract AINFTFactory is Ownable {

    constructor() Ownable() {}

    function cloneERC721(
        ERC721 originalNFT_,
        string memory newName_,
        string memory newSymbol_
    ) public returns (address) {
        address originalNFTAddr = address(originalNFT_);
        require(originalNFTAddr != address(0), ""); 
        
        AINFT721 clone = _cloneInstanceAINFT721(originalNFT_, newName_, newSymbol_); // msg.sender is admin
        return address(clone);
    }

    function _cloneInstanceAINFT721(
        ERC721 originalNFT_,
        string memory name_,
        string memory symbol_
    ) internal returns (AINFT721) {
        AINFT721 ainft721 = new AINFT721(name_, symbol_, true, address(originalNFT_));
        return ainft721;
    }

    function _createInstanceAINFT721(
        string memory name_,
        string memory symbol_
    ) internal returns (AINFT721) {
        return new AINFT721(name_, symbol_, false, address(0));
    }

    function createAINFT721(
        string memory name_,
        string memory symbol_
    ) public returns (AINFT721) {
        return _createInstanceAINFT721(name_, symbol_);
    }
}
