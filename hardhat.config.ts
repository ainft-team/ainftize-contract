import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
// import "@openzeppelin/hardhat-upgrades"
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";
// import "hardhat-contract-sizer";
import "solidity-docgen";
// import "@typechain/hardhat";

// import "./scripts/deploy";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    // refer to https://docs.soliditylang.org/en/v0.8.18/using-the-compiler.html
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  // contractSizer: {
  //   alphaSort: true,
  //   runOnCompile: true,
  //   disambiguatePaths: false,
  //   strict: true, // throws an error if your code exceeds 24576 Bytes, refer to https://github.com/ItsNickBarry/hardhat-contract-sizer/blob/95b202e75df3cc3fe309332bb8fa2062ad9a6ea2/tasks/size_contracts.js#L22
  // },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    goerli: {
      url: process.env.GOERLI_URL !== undefined ? process.env.GOERLI_URL : "",
      accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    sepolia: {
      url: process.env.SEPOLIA_URL !== undefined ? process.env.SEPOLIA_URL : "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mainnet: {
      url: process.env.MAINNET_URL !== undefined ? process.env.MAINNET_URL : "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: (process.env.REPORT_GAS) ? true : false,
    currency: 'KRW',
    token: 'ETH',
    // gasPrice: 11,
    gasPriceApi: "https://api.etherscan.io/api?module=proxy&action=eth_gasPrice",
    coinmarketcap: (process.env.COINMARKETCAP_API_KEY !== undefined) ? process.env.COINMARKETCAP_API_KEY : undefined
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  docgen: {
    pages: () => 'api.md',
  }
};

export default config;
