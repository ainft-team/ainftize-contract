import { ethers, upgrades } from "hardhat";
import { AINFT721Upgradeable__factory, AINFT721LogicV2__factory } from "../typechain-types";
import { proxy } from "../typechain-types/@openzeppelin/contracts-upgradeable";

async function main() {
  // Deploy the proxy contract
  const AINFT721Upgradeable: AINFT721Upgradeable__factory = await ethers.getContractFactory("AINFT721Upgradeable");
  const proxyContract = await upgrades.deployProxy(
    AINFT721Upgradeable,
    ["Deploy AINFT for test", "AINFT"],
    {
      initializer: "initialize",
      kind: 'uups',
    });
    
  await proxyContract.deployed();

  console.log("Proxy Contract address:  ", proxyContract.address);
  console.log("deployer:                ", await proxyContract.signer.getAddress())
  console.log("Name:                    ", await proxyContract.name());
  console.log("Symbol:                  ", await proxyContract.symbol());
  console.log("logicVersion:            ", await proxyContract.logicVersion());

  // Upgrade logic contract

  const AINFT721LogicV2: AINFT721LogicV2__factory = await ethers.getContractFactory("AINFT721LogicV2");
  const logicV2Contract = await upgrades.upgradeProxy(
    proxyContract.address,
    AINFT721LogicV2,
    {
      kind: 'uups',
    }
  )

  console.log("Logic Contract address:  ", logicV2Contract.address);
  console.log("deployer:                ", await logicV2Contract.signer.getAddress());
  console.log("logicVersion:            ", await proxyContract.logicVersion());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
