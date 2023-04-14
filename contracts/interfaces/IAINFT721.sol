// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IAINFT.sol";

interface IAINFT721 is IERC721, IAINFT {}