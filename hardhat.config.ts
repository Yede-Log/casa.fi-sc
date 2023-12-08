import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
        optimizer: {
            enabled: true,
            runs: 100
        },
        viaIR: true
    }
  },
  networks: {
    polygon_mumbai: {
        url: 'https://rpc-mumbai.maticvigil.com',
        accounts: [vars.get("ACCOUNT_PRIVATE_KEY")]
    },
    polygon_zkevm: {
        url: "",
        accounts: [vars.get("ACCOUNT_PRIVATE_KEY")]
    },
    eth_sepolia: {
        url: 'http://localhost:8546',
        accounts: [vars.get("ACCOUNT_PRIVATE_KEY")]
    },
    linea: {
        url: "",
        accounts: [vars.get("ACCOUNT_PRIVATE_KEY")]
    },
    base_goerli: {
        url: '',
        accounts: [vars.get("ACCOUNT_PRIVATE_KEY")]
    }
  }
};

export default config;
