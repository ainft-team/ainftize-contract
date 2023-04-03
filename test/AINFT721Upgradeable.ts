// test/AINFT721Upgradeable.test.js
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { formatBytes32String, keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { utils } from "ethers";
import * as dotenv from "dotenv";
dotenv.config();
import { AINFT721Upgradeable, AINFT721Upgradeable__factory } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("AINFT721Upgradeable", function () {
  let AINFT721Factory: AINFT721Upgradeable__factory;
  let proxyContract: AINFT721Upgradeable | any;
  let owner: SignerWithAddress;
  let minter: SignerWithAddress;
  let pauser: SignerWithAddress;
  let upgrader: SignerWithAddress;
  let addrs: SignerWithAddress[];
  let baseURI: string;
  let deployedTx;
  let deployer: string;

  beforeEach(async function () {
    AINFT721Factory = await ethers.getContractFactory("AINFT721Upgradeable");
    [owner, minter, pauser, upgrader, ...addrs] = await ethers.getSigners();

    proxyContract = await upgrades.deployProxy(
      AINFT721Factory,
      ["AINFT contract name", "AINFTSYMBOL"],
      {
        initializer: "initialize",
        kind: 'uups',
      }
    );
    deployedTx = await proxyContract.deployed();
    deployer = deployedTx.deployTransaction.from;

    await proxyContract.grantRole(proxyContract.PAUSER_ROLE(), pauser.address);
    await proxyContract.grantRole(proxyContract.MINTER_ROLE(), minter.address);
    await proxyContract.grantRole(proxyContract.UPGRADER_ROLE(), upgrader.address);

    baseURI = "http://localhost:3000/token";
    await proxyContract.setBaseURI(baseURI);
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(deployer).to.equal(owner.address);
    });

    it("Should set the right name", async function () {
      expect(await proxyContract.name()).to.equal("AINFT contract name");
    });

    it("Should set the right symbol", async function () {
      expect(await proxyContract.symbol()).to.equal("AINFTSYMBOL");
    });
  });

  describe("Minting", function () {
    it("Should mint a new token", async function () {
      await proxyContract.safeMint(owner.address);
      expect(await proxyContract.totalSupply()).to.equal(1);
    });

    it("Should not allow non-minter to mint a token", async function () {
      const non_minter = addrs[0];

      expect(await proxyContract.hasRole(proxyContract.MINTER_ROLE(), non_minter.address)).to.equal(false);
      await expect(proxyContract.connect(non_minter).safeMint(non_minter.address)).to.be.reverted;
    });
  });

  describe("Token URI & Update Metadata", function () {
    it("Should return based on the baseURI if token metadata is not updated yet", async function () {
      await proxyContract.safeMint(owner.address);
      expect(await proxyContract.tokenURI(0)).to.equal(`${baseURI}/0`);
    });

    it("Should not allow to get token URI for non-existent token", async function () {
      await expect(proxyContract.tokenURI(0)).to.be.reverted;
    });

    it("Should update URI correctly", async function () {
      await proxyContract.safeMint(owner.address);
      expect(await proxyContract.updateTokenURI(0, 'ipfs://newTokenURI')).not.to.be.reverted;
      expect(await proxyContract.tokenURI(0)).not.to.be.equal(`${baseURI}/0`);
      expect(await proxyContract.tokenURI(0)).to.be.equal('ipfs://newTokenURI');
    });

    it("Should not change URI if sender is not owner of tokenId", async function () {
      await proxyContract.connect(minter).safeMint(minter.address);

      await expect(proxyContract.connect(addrs[0]).updateTokenURI(0, 'ipfs://newTokenURI')).to.be.reverted;
      await expect(proxyContract.connect(minter).updateTokenURI(0, 'ipfs://newTokenURI')).not.to.be.reverted;
      expect(await proxyContract.tokenURI(0)).to.be.equal('ipfs://newTokenURI');
    });
  });

  describe("Pausing", function () {
    it("Should pause the contract", async function () {
      await proxyContract.pause();
      expect(await proxyContract.paused()).to.equal(true);
    });

    it("Should not allow non-pauser to pause the contract", async function () {
      await expect(proxyContract.connect(addrs[0]).pause()).to.be.reverted;
    });

    it("Should unpause the contract", async function () {
      await proxyContract.pause();
      await proxyContract.unpause();
      expect(await proxyContract.paused()).to.equal(false);
    });

    it("Should not allow non-pauser to unpause the contract", async function () {
      await expect(proxyContract.connect(addrs[0]).unpause()).to.be.reverted;
    });
  });

  describe("Upgrading", function () {
    it("Should upgrade the implementation contract with logicV2", async function () {
      expect(await proxyContract.logicVersion()).to.equal("1");

      const logicV2Factory = await ethers.getContractFactory("AINFT721LogicV2");
      const logicV2Contract = await upgrades.upgradeProxy(
        proxyContract.address,
        logicV2Factory,
        {
          kind: 'uups', 
        }
      );
      expect(await proxyContract.logicVersion()).to.equal("2");
    });

    it("Should not allow non-upgrader to upgrade the implementation contract", async function () {

      const not_owner = addrs[2];
      const logicV2Factory = await ethers.getContractFactory("AINFT721LogicV2");
      const logicV2Address = await logicV2Factory.deploy().then((contract) => contract.address);

      await expect(proxyContract.connect(not_owner).upgradeTo(logicV2Address)).to.be.reverted;
      await expect(proxyContract.connect(owner).upgradeTo(logicV2Address)).not.to.be.reverted;
    });

  });

});
