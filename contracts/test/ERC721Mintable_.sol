// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
contract ERC721Mintable_ is ERC721 {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}
    function mint(
        address to,
        uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}