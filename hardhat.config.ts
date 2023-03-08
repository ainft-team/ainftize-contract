import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@openzeppelin/hardhat-upgrades"
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";
import "solidity-docgen";
import { userConfig } from "hardhat";

// import "./scripts/deploy";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      metadata: {
        bytecodeHash: "none",
      },
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
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
