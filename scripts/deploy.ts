import { ethers } from "hardhat";
import { BigNumber } from "ethers";

const params = {
    name: "Sample AINFT721",
    symbol: "SAINFT",
    isCloned: false,
    originNFT:    "0x0000000000000000000000000000000000000000",
}

async function getSigner(privKey?: string) {
  if (privKey) {
    const wallet = new ethers.Wallet(privKey);
    const signer = wallet.connect(ethers.provider);
    return signer;
  } else {
    const accounts = await ethers.getSigners();
    return accounts[0];
  }
}


async function main() {
  const signer = await getSigner(process.env.PRIVATE_KEY || "");

  /* Deployment */
  const Ain = await ethers.getContractFactory("ERC20", signer);
  const ain = await Ain.deploy("AI Network ERC20 token", "AIN");
  await ain.deployed();
  console.log("AIN deployed to:", ain.address);

  const Ainft721 = await ethers.getContractFactory("AINFT721", signer);
  const ainft721 = await Ainft721.deploy(
    params.name,
    params.symbol,
    params.isCloned,
    params.originNFT
  );
  await ainft721.deployed();
  console.log("AINFT721 deployed to:", ainft721.address);

  const Ainpayment = await ethers.getContractFactory("AINPayment", signer);
  const ainpayment = await Ainpayment.deploy(ainft721.address, ain.address);
  await ainpayment.deployed();
  console.log("AINPayment deployed to:", ainpayment.address);

  /* Post setting after deploying */
  await ainft721.setPaymentContract(ainpayment.address);
  // await ainpayment.setPrice([0, 0]);
  await ainft721.safeMint(signer.address, 0); // mint tokenId #0 of AINFT721
  await ainft721.setApprovalForAll(ainpayment.address, true);
  await ain.approve(ainpayment.address, BigNumber.from('1000000000000000000'));  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
