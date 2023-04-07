// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IAINFT.sol";

///@notice AINPayment address should be registered PAYMENT_ROLE in AINFT721.sol
contract AINPayment is Ownable, ReentrancyGuard {
    IERC20 public _ain;
    IAINFT public _ainft;

    uint256[2] public _price; // [update_price, rollback_price]

    constructor(address ainft, address ain) {
        // require(ain == 0x3A810ff7211b40c4fA76205a14efe161615d0385, "AINPayment: only supports AIN ERC20");
        _ain = IERC20(ain);
        _ainft = IAINFT(ainft);
        _price = [0, 0];
    }

    function setPrice(uint256[2] calldata price) external onlyOwner {
        require(!(_price[0] == price[0] && _price[1] == price[1]), "AINPayment::setPrice, the new price is same as the old one.");
        _price[0] = price[0];
        _price[1] = price[1];
    }


    /**
     * @dev Pay AIN to AINPayment contract
     * @param amount Amount of AIN to pay
     * @notice Before executing _pay(), _ain.approve(address(this), type(uint256).max) should be called by user.
     * */
    function _pay(uint256 amount) internal nonReentrant returns(bool) {
        require(amount > 0, "AINPayment::_pay, Amount must be greater than 0");
        require(_ain.balanceOf(_msgSender()) >= amount, "AINPayment::_pay, Insufficient balance");

        bool success = _ain.transferFrom(_msgSender(), address(this), amount);
        return success;
    }

    function executeUpdate(uint256 tokenId, string memory newTokenURI) external returns(bool) {
        require(_ainft.isApprovedOrOwner(_msgSender(), tokenId), "AINPayment::executeUpdate, owner of AINFT or holder only call this");
        require(_pay(_price[0]), "AINPayment::executeUpdate, Insufficient AIN");
        bool success = _ainft.updateTokenURI(tokenId, newTokenURI);
        return success;
    }

    function executeRollback(uint256 tokenId) external returns(bool) {
        require(_ainft.isApprovedOrOwner(_msgSender(), tokenId), "AINPayment::executeRollback, owner of AINFT or holder only call this");
        require(_pay(_price[1]), "AINPayment::executeRollback, Insufficient AIN");

        bool success = _ainft.rollbackTokenURI(tokenId);
        return success;
    }

    function withdraw(uint256 amount) public onlyOwner nonReentrant returns(bool) {
        require(owner() != address(0), "Owner should be set");
        require(_ain.balanceOf(address(this)) >= amount, "AINPayment::withdraw, Insufficient AIN");

        bool success = _ain.transfer(owner(), amount);
        return success;
    }
    function withdrawAll() public onlyOwner nonReentrant returns(bool) {
        require(owner() != address(0), "AINPayment::withdrawAll, Owner should be set");

        uint256 balance = _ain.balanceOf(address(this));
        require(balance > 0, "AINPayment::withdrawAll, No AIN tokens to withdraw");

        bool success = _ain.transfer(owner(), balance);
        return success;
    }

    function destruct(string memory areYouSure) external payable onlyOwner {
        require(owner() != address(0), "AINPayment::destruct, Owner should be set");
        require(keccak256(abi.encodePacked(areYouSure)) == keccak256(abi.encodePacked("DELETE")), "Please type DELETE if you really want to destruct");

        // 1. withdraw all AIN to owner        
        require(withdrawAll(), "AINPayment::destruct, Failed to withdraw all AIN");

        // 2. withdraw all ethers stored in this contract to owner
        address payable _owner = payable(owner());
        uint256 balance = address(this).balance;
        require(balance > 0, "AINPayment::destruct, The contract has no funds to withdraw");
        
        // For the solidity's vulnerability of using transfer(), use call instead. 
        // https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        (bool success, ) = _owner.call{ value: balance }("");
        require(success, "AINPayment::destruct, Failed to withdraw all ethers");
    }
}
