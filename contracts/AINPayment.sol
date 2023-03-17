// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IAINPayment.sol";
import "../interfaces/IAINFT.sol";

contract AINPayment is Ownable, ReentrancyGuard {
    IERC20 public _ain;
    IAINFT public _ainft;

    uint256[2] public _price; // [update_price, rollback_price]

    constructor(address ainft, address ain) {
        require(ain == 0x3a810ff7211b40c4fa76205a14efe161615d0385, "AINPayment: only supports AIN ERC20");
        _ain = IERC20(ain);
        _ainft = IAINFT(ainft);
        _price = [0, 0];

    }

    modifier checkAllowance(uint256 amount) {
        require(_ain.allowance(_msgSender(), address(this)) >= amount, "Allowance is smaller than amount");
        _;
    }

    function setPrice(uint256[2] calldata price) external onlyOwner {
        require(!(_price[0] == price[0] && _price[1] == price[1]), "AINPayment::setPrice, the new price is same as the old one.");
        _price[0] = price[0];
        _price[1] = price[1];
    }

    function pay(uint256 amount) public nonReentrant returns(success) {
        require(amount > 0, "Amount must be greater than 0");
        require(_ain.balanceOf(_msgSender()) >= amount, "Insufficient balance");
        
        bool success = _ain.transfer(address(this), amount);        
    }

    function executeUpdate(uint256 tokenId, string memory newTokenURI) external returns(success) {
        require(_ainft.isApprovedOrOwner(_msgSender(), tokenId), "AINPayment::executeUpdate, owner of AINFT or holder only call this");
        require(pay(_price[0]), "Insufficient AIN");

        bool success = _ainft.updateTokenURI(tokenId, newTokenURI);
    }

    function executeRollback(uint256 tokenId) external returns(success) {
        require(_ainft.isApprovedOrOwner(_msgSender(), tokenId), "AINPayment::executeRollback, owner of AINFT or holder only call this");
        require(pay(_price[1]), "Insufficient AIN");

        bool success = _ainft.rollbackTokenURI(tokenId);
    }

    function withdraw(uint256 amount) external onlyOwner nonReentrant returns(success) {
        require(owner() != address(0), "Owner should be set");
        require(_ain.balanceOf(address(this)) >= amount, "Insufficient balance");

        _ain.approve(owner(), amount);
        require(_ain.allowance(address(this), owner()) >= amount, "Insufficient amount is allowed");
        bool success = _ain.transferFrom(address(this), owner(), amount);
    }

    function withdrawAll() external onlyOwner nonReentrant returns(success) {
        require(owner() != address(0), "Owner should be set");
        require(_ain.allowance(address(this), owner()) >= amount, "Insufficient amount is allowed");

        uint256 stackedAin = _ain.balanceOf(address(this));
        _ain.approve(owner(), stackedAin);
        require(_ain.allowance(address(this), owner()) >= stackedAin, "Insufficient amount is allowed");
        bool success = _ain.transferFrom(address(this), owner(), stackedAin);
    }

    function destruct(string memory areYouSure) external payable onlyOwner {
        require(owner() != address(0), "Owner should be set");
        require(areYouSure == "DELETE", "Please type DELETE if you really want to destruct");
        
        withdrawAll();
        selfdestruct(payable(owner()));
    }
}
