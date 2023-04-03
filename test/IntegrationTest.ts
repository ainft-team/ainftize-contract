// test/AINFT721Upgradeable.test.js
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();

import { 
    AINFT721__factory,
    AINFT721,
    AINPayment__factory,
    AINPayment,
    AINFTFactory__factory,
    AINFTFactory,
    ERC721Mintable___factory,
    ERC721Mintable_,
    ERC20___factory,
    ERC20_
 } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("Integration test: Cloning", function () {
  let Erc20: ERC20___factory;  
  let erc20: ERC20_;  
  let Erc721Mintable: ERC721Mintable___factory;
  let erc721mintable: ERC721Mintable_;
  let Ainft721: AINFT721__factory;
  // let ainft721: AINFT721;
  let Ainpayment: AINPayment__factory;
  // let ainpayment: AINPayment;
  let Ainftfactory: AINFTFactory__factory;
  let ainftfactory: AINFTFactory;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let pauser: SignerWithAddress;
  let payer: SignerWithAddress;
  let addrs: SignerWithAddress[];
  let baseURI: string;
  let deployedTx;
  let deployer: string;

  beforeEach(async function () {
    const provider = new ethers.providers.JsonRpcProvider();
    [owner, minter, pauser, payer, ...addrs] = await ethers.getSigners();
    console.log("owner: ", owner.address);
    console.log("minter: ", minter.address);
    console.log("pauser: ", pauser.address);
    console.log("payer: ", payer.address);

    Erc20 = await ethers.getContractFactory("ERC20_");
    erc20 = await Erc20.deploy("AI Network", "AIN", BigNumber.from('10000000000000000000000'));    
    await erc20.deployed();

    console.log("ERC20 Contract At: ", erc20.address);
    console.log("TotalSupply: ", await erc20.totalSupply());
    console.log("Balance of owner: ", await erc20.balanceOf(await owner.getAddress()));

    Erc721Mintable = await ethers.getContractFactory("ERC721Mintable_");
    erc721mintable = await Erc721Mintable.deploy("TEST_ERC721", "ERC721");
    await erc721mintable.deployed(); 
    console.log("ERC721Mintable Contract At: ", erc721mintable.address);

    Ainftfactory = await ethers.getContractFactory("AINFTFactory");
    ainftfactory = await Ainftfactory.deploy();
    await ainftfactory.deployed();
    console.log("AINFTFactory Contract At: ", ainftfactory.address);

    Ainpayment = await ethers.getContractFactory("AINPayment");
  });

  describe("Clone AINFT721", function () {
    it("should clone AINFT721 from AINFTFactory, permit mint only original NFT's holder", async function() {
      let ainft721: AINFT721;
      
      const ainftfactory_tx = await ainftfactory.connect(owner).cloneERC721(erc721mintable.address, "AINFT721", "AINFT");
      await ainftfactory_tx.wait(1);

      // Cloned ainft721 contract address
      const ainft721Address = await ainftfactory.getClonedAINFTContract();
      ainft721 = await ethers.getContractAt("AINFT721", ainft721Address, owner);
      console.log("AINFT721 Contract At: ", ainft721Address);
      await expect(ainft721.hasRole(ainft721.DEFAULT_ADMIN_ROLE(), owner.address)).not.to.be.reverted;
      expect(await ainft721.IS_CLONED()).to.equal(true);  

      // grant roles to ainft721
      await ainft721.grantRole(ainft721.PAUSER_ROLE(), pauser.address);
      await ainft721.grantRole(ainft721.MINTER_ROLE(), minter.address);

      // set Base URI
      const baseURI = "https://ainetwork.ai/ainft/";
      await ainft721.setBaseURI(baseURI);

      const tokenId_owner = 0;
      const tokenId_minter = 1;
      const tokenId_another1 = 2;
      const tokenId_another2 = 3;
      
      // The original NFT holder - owner have #0, minter have #1
      const mintTx1 = await erc721mintable.mint(owner.address, tokenId_owner);
      const mintTx2 = await erc721mintable.mint(minter.address, tokenId_minter);
      expect(await erc721mintable.ownerOf(tokenId_owner)).to.equal(owner.address);
      expect(await erc721mintable.ownerOf(tokenId_minter)).to.equal(minter.address);
      expect(await ainft721.ORIGIN_NFT()).to.equal(erc721mintable.address);
      mintTx1.wait();
      mintTx2.wait();
      console.log('ERC721Mintable token #0 owner: ', await erc721mintable.ownerOf(tokenId_owner));
      console.log('ORIGIN_NFT == ERC721Mintable? : ', await ainft721.ORIGIN_NFT(), erc721mintable.address);
    
      // ONLY can mint AINFT corrresponding to original NFT(erc721mintable)'s tokenId
      await expect(ainft721.connect(owner).mintFromOriginInstance(tokenId_minter)).to.be.reverted;
      await expect(ainft721.connect(owner).mintFromOriginInstance(tokenId_owner)).not.to.be.reverted;
      await expect(ainft721.connect(minter).mintFromOriginInstance(tokenId_owner)).to.be.reverted;
      await expect(ainft721.connect(minter).mintFromOriginInstance(tokenId_minter)).not.to.be.reverted;
      
      // Should not be minted twice
      await expect(ainft721.connect(owner).mintFromOriginInstance(tokenId_owner)).to.be.reverted;

      // Other account(one of addr) can't mint vacant AINFT
      await expect(ainft721.connect(addrs[0]).mintFromOriginInstance(tokenId_another1)).to.be.reverted;

      // minter can mint AINFT on behalf of the others
      const mintTx3 = await erc721mintable.mint(addrs[0].address, tokenId_another2);
      mintTx3.wait();
      await expect(ainft721.connect(minter).mintFromOriginInstanceOnBehalf([tokenId_another2], [addrs[0].address])).not.to.be.reverted;

    });
  });

  describe("Create New AINFT721", function () {
    it("should generate AINFT721 from AINFTFactory, permit mint only original NFT's holder", async function() {
      let ainft721: AINFT721;

      const ainftfactory_tx = await ainftfactory.connect(owner).createAINFT721("AINFT721", "AINFT");
      await ainftfactory_tx.wait(1);

      //create ainft721 contract address
      const ainft721Address = await ainftfactory.getCreatedAINFTContract();
      ainft721 = await ethers.getContractAt("AINFT721", ainft721Address, owner);
      console.log("AINFT721 Contract At: ", ainft721Address);
      await expect(ainft721.hasRole(ainft721.DEFAULT_ADMIN_ROLE(), owner.address)).not.to.be.reverted;
      expect(await ainft721.IS_CLONED()).to.equal(false);

      // grant roles to ainft721
      await ainft721.grantRole(ainft721.PAUSER_ROLE(), pauser.address);
      await ainft721.grantRole(ainft721.MINTER_ROLE(), minter.address);

      const tokenId_owner = 0;
      const tokenId_minter = 1;
      const tokenId_another1 = 2;
      const tokenId_another2 = 3;

      // Cannot use functions which put Cloned modifier
      await expect(ainft721.connect(owner).mintFromOriginInstance(tokenId_owner)).to.be.reverted;
      await expect(ainft721.connect(minter).mintFromOriginInstance(tokenId_minter)).to.be.reverted;
      await expect(ainft721.connect(minter).mintFromOriginInstanceOnBehalf([tokenId_another2], [addrs[0].address])).to.be.reverted;
    });
  });

  describe("AINPayment added to AINFT721", function () {
    it("should add AINPayment to AINFT721", async function() {
      let ainft721: AINFT721;
      let ainpayment: AINPayment;

      const ainftfactory_tx = await ainftfactory.connect(owner).createAINFT721("AINFT721", "AINFT");
      await ainftfactory_tx.wait(1);

      //create ainft721 contract address
      const ainft721Address = await ainftfactory.getCreatedAINFTContract();
      ainft721 = await ethers.getContractAt("AINFT721", ainft721Address, owner);
      expect(await ainft721.hasRole(ainft721.DEFAULT_ADMIN_ROLE(), owner.address)).to.equal(true);
      expect(await ainft721.IS_CLONED()).to.equal(false);
      console.log("AINFT721 Contract At: ", ainft721Address);

      // grant roles to ainft721
      await expect(ainft721.grantRole(ainft721.PAUSER_ROLE(), pauser.address)).not.to.be.reverted;
      await expect(ainft721.grantRole(ainft721.MINTER_ROLE(), minter.address)).not.to.be.reverted;

      // set Base URI
      const baseURI = "https://ainetwork.ai/ainft/";
      await expect(ainft721.setBaseURI(baseURI)).not.to.be.reverted;

      // Create AINPayment
      ainpayment = await Ainpayment.deploy(ainft721.address, erc20.address);
      await ainpayment.deployed();
      console.log("AINPayment Contract At: ", ainpayment.address);
      
      // Connect AINPayment to AINFT721
      await expect(ainft721.connect(owner).setPaymentContract(ainpayment.address)).not.to.be.reverted;
      expect(await ainft721.PAYMENT_PLUGIN()).to.equal(ainpayment.address);

      // setPrice to AINPayment
      const [updatedPrice, rollbackPrice] = [1, 2];
      await expect(ainpayment.connect(owner).setPrice([updatedPrice, rollbackPrice])).not.to.be.reverted; // update_price, rollback_price
      expect(await ainpayment._price(0)).to.equal(updatedPrice);
      expect(await ainpayment._price(1)).to.equal(rollbackPrice);

      // executeUpdate AINFT721 via AINPayment
      const [tokenId_owner, tokenId_minter, tokenId_another1, tokenId_another2] = [0, 1, 2, 3];
      const newTokenURI_0 = "https://ainetwork.ai/ainft/0-v2";

      // mint AINFT #0, #1
      await expect(ainft721.connect(owner).safeMint(owner.address, tokenId_owner)).not.to.be.reverted;
      await expect(ainft721.connect(minter).safeMint(minter.address, tokenId_minter)).not.to.be.reverted;
      
      // Cannot executeUpdate if not token holder
      await expect(ainpayment.connect(addrs[0]).executeUpdate(tokenId_owner, newTokenURI_0)).to.be.reverted;

      // Can executeUpdate if token holder
      // approve from owner to AINPayment to give permission of AIN
      // decrease owner's AIN balance
      // update the owner's tokenId of AINFT721 tokenURI
      const ownerInitBalance = await erc20.balanceOf(await owner.getAddress());
      await expect(erc20.connect(owner).approve(ainpayment.address, updatedPrice)).not.to.be.reverted;
      expect(await erc20.allowance(owner.address, ainpayment.address)).to.equal(updatedPrice);
      await expect(ainpayment.connect(owner).executeUpdate(tokenId_owner, newTokenURI_0)).not.to.be.reverted;
      const ownerUpdatedBalance = await erc20.balanceOf(await owner.getAddress());
      expect(ownerInitBalance.sub(ownerUpdatedBalance)).to.equal(updatedPrice);
      await expect(ainft721.connect(owner).tokenURI(tokenId_owner)).to.eventually.equal(newTokenURI_0);

            
      // Cannot rollbackUpdate if not token holder
      await expect(ainpayment.connect(addrs[0]).executeRollback(tokenId_owner)).to.be.reverted;

      // Can rollbackUpdate if token holder
      // decrease owner's AIN balance
      // rollback the owner's tokenId of AINFT721 tokenURI
      await expect(erc20.connect(owner).approve(ainpayment.address, rollbackPrice)).not.to.be.reverted;
      expect(await erc20.allowance(owner.address, ainpayment.address)).to.equal(rollbackPrice);
      await expect(ainpayment.connect(owner).executeRollback(tokenId_owner)).not.to.be.reverted;
      const ownerRollbackBalance = await erc20.balanceOf(await owner.getAddress());
      expect(ownerUpdatedBalance.sub(ownerRollbackBalance).toNumber()).to.equal(rollbackPrice);
      await expect(ainft721.connect(owner).tokenURI(tokenId_owner)).to.eventually.equal("https://ainetwork.ai/ainft/0"); // default tokenURI
    });
  });

  describe("AINPayment destruction", function () {
    let ainft721: AINFT721;
    let ainpayment: AINPayment;

    beforeEach(async function () {
      const ainftfactory_tx = await ainftfactory.connect(owner).createAINFT721("AINFT721", "AINFT");
      await ainftfactory_tx.wait(1);

      //create ainft721 contract address
      const ainft721Address = await ainftfactory.getCreatedAINFTContract();
      ainft721 = await ethers.getContractAt("AINFT721", ainft721Address, owner);
      console.log("AINFT721 Contract At: ", ainft721Address);
      expect(await ainft721.hasRole(ainft721.DEFAULT_ADMIN_ROLE(), owner.address)).to.equal(true);
      expect(await ainft721.IS_CLONED()).to.equal(false);

      // grant roles to ainft721
      await expect(ainft721.grantRole(ainft721.PAUSER_ROLE(), pauser.address)).not.to.be.reverted;
      await expect(ainft721.grantRole(ainft721.MINTER_ROLE(), minter.address)).not.to.be.reverted;

      // set Base URI
      const baseURI = "https://ainetwork.ai/ainft/";
      await ainft721.setBaseURI(baseURI);

      // Create AINPayment
      ainpayment = await Ainpayment.deploy(ainft721.address, erc20.address);
      await ainpayment.deployed();
      console.log("AINPayment Contract At: ", ainpayment.address);
      console.log("Connected AIN contract: ", await ainpayment._ain());
      console.log("Connected AINFT contract: ", await ainpayment._ainft());
      
      // Connect AINPayment to AINFT721
      await ainft721.connect(owner).setPaymentContract(ainpayment.address);
      expect(await ainft721.PAYMENT_PLUGIN()).to.equal(ainpayment.address);

      // Give 100 AIN and 1 ETH to AINPayment
      await erc20.connect(owner).transfer(ainpayment.address, ethers.utils.parseEther("100"));
      await ethers.provider.send("hardhat_setBalance", [ainpayment.address, "0xde0b6b3a7640000"]); // 1 ETH
    });

    it("should withdraw AINPayment", async function () {
      // owner withdraw all AINPayment
      const [ownerInitAIN, ownerInitETH] = await Promise.all([
        erc20.balanceOf(await owner.getAddress()),
        ethers.provider.getBalance(await owner.getAddress())
      ]);
      const [ainpaymentInitAIN, ainpaymentInitETH] = await Promise.all([
        erc20.balanceOf(ainpayment.address),
        ethers.provider.getBalance(ainpayment.address)
      ]);
      
      await expect(ainpayment.connect(owner).withdraw(1)).not.to.be.reverted;
      await expect(ainpayment.connect(owner).withdrawAll()).not.to.be.reverted;
      
      const [ownerUpdatedAIN, ownerUpdatedETH] = await Promise.all([
        erc20.balanceOf(await owner.getAddress()),
        ethers.provider.getBalance(await owner.getAddress())
      ]);
      const [ainpaymentUpdatedAIN, ainpaymentUpdatedETH] = await Promise.all([
        erc20.balanceOf(ainpayment.address),
        ethers.provider.getBalance(ainpayment.address)
      ]);

      expect(ownerInitAIN.add(ainpaymentInitAIN)).to.equal(ownerUpdatedAIN);
      expect(ownerUpdatedETH.sub(ainpaymentInitETH)).to.lessThan(ownerInitETH);
      console.log("Before balance of AinPayment(AIN:ETH): ", ainpaymentInitAIN.toString(), ainpaymentInitETH.toString());
      console.log("After balance of AinPayment(AIN:ETH): ", ainpaymentUpdatedAIN.toString(), ainpaymentUpdatedETH.toString());
    });
    it("should not withdraw AINPayment except owner", async function () {
      // minter tries to withdraw all AINPayment
      const [minterInitAIN, minterInitETH] = await Promise.all([
        erc20.balanceOf(await minter.getAddress()),
        ethers.provider.getBalance(await minter.getAddress())
      ]);
      const [ainpaymentInitAIN, ainpaymentInitETH] = await Promise.all([
        erc20.balanceOf(ainpayment.address),
        ethers.provider.getBalance(ainpayment.address)
      ]);
      
      await expect(ainpayment.connect(minter).withdraw(1)).to.be.reverted;
      await expect(ainpayment.connect(minter).withdrawAll()).to.be.reverted;
      
    });

    it("should destroy AINPayment", async function () {
      // destroy AINPayment
      const [ownerInitAIN, ownerInitETH] = await Promise.all([
        erc20.balanceOf(await owner.getAddress()),
        ethers.provider.getBalance(await owner.getAddress())
      ]);
      const [ainpaymentInitAIN, ainpaymentInitETH] = await Promise.all([
        erc20.balanceOf(ainpayment.address),
        ethers.provider.getBalance(ainpayment.address)
      ]);
      
      //destruct AINPayment
      await expect(ainpayment.connect(owner).destruct("NOTDELETE")).to.be.reverted; // revert if not "DELETE"
      await expect(ainpayment.connect(owner).destruct("DELETE")).not.to.be.reverted;
      
      const [ownerUpdatedAIN, ownerUpdatedETH] = await Promise.all([
        erc20.balanceOf(await owner.getAddress()),
        ethers.provider.getBalance(await owner.getAddress())
      ]);
      const [ainpaymentUpdatedAIN, ainpaymentUpdatedETH] = await Promise.all([
        erc20.balanceOf(ainpayment.address),
        ethers.provider.getBalance(ainpayment.address)
      ]);

      expect(ownerInitAIN.add(ainpaymentInitAIN)).to.equal(ownerUpdatedAIN);
      expect(ownerUpdatedETH.sub(ainpaymentInitETH)).to.lessThan(ownerInitETH);
      console.log("Before balance of AinPayment(AIN:ETH): ", ainpaymentInitAIN.toString(), ainpaymentInitETH.toString());
      console.log("After balance of AinPayment(AIN:ETH): ", ainpaymentUpdatedAIN.toString(), ainpaymentUpdatedETH.toString());
    
    });

    it("should not destroy AINPayment except owner", async function () {
      // destroy AINPayment from minter
      const [minterInitAIN, minterInitETH] = await Promise.all([
        erc20.balanceOf(await minter.getAddress()),
        ethers.provider.getBalance(await minter.getAddress())
      ]);
      const [ainpaymentInitAIN, ainpaymentInitETH] = await Promise.all([
        erc20.balanceOf(ainpayment.address),
        ethers.provider.getBalance(ainpayment.address)
      ]);
      
      //destruct AINPayment - revert
      await expect(ainpayment.connect(minter).destruct("NOTDELETE")).to.be.reverted; // revert if not "DELETE"
      await expect(ainpayment.connect(minter).destruct("DELETE")).to.be.reverted; // revert if not owner    
    });
  });
});