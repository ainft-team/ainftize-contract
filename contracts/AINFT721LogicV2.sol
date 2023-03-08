// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AINFT721Upgradeable.sol";

contract AINFT721LogicV2 is AINFT721Upgradeable {
    /**
     * @dev execute the additional function updated to proxy contract.
     */
    function example__resetTokenURI(uint256 tokenId) external returns (bool) {
        require(
            (_msgSender() == ownerOf(tokenId)) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AINFT721LogicV2::example__resetTokenURI() - only contract owner or token holder can call this funciton."
        );
        bool ret = true;
        uint256 currentVersion = tokenURICurrentVersion[tokenId];
        for (uint256 i = currentVersion; i > 0; i--) {
            bool success = _rollbackTokenURI(tokenId);
            ret = ret || success;
        }
        return ret;
    }

    /**
     * @dev get the logic contract version
     */
    function logicVersion() external virtual override returns (uint256) {
        return 2;
    }
}
