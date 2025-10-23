// hardhat.config.cjs
const dotenv = require("dotenv");
require("@nomicfoundation/hardhat-toolbox");

dotenv.config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const SEPOLIA_PRIVATE_KEY = process.env.SEPOLIA_PRIVATE_KEY
  ? [process.env.SEPOLIA_PRIVATE_KEY]
  : [];

module.exports = {
  solidity: {
    version: "0.8.30",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      type: "edr-simulated",
      chainId: 31337,
    },
    sepolia: {
      type: "http",
      url: SEPOLIA_RPC_URL,
      accounts: SEPOLIA_PRIVATE_KEY,
      chainId: 11155111,
    },
  },
};
