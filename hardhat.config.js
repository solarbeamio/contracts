require("dotenv/config");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("./tasks");

let accounts;

if (process.env.PRIVATE_KEY) {
    accounts = [process.env.PRIVATE_KEY];
} else {
    accounts = {
        mnemonic: process.env.MNEMONIC || "test test test test test test test test test test test junk",
    };
}

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    defaultNetwork: "hardhat",
    namedAccounts: {
        deployer: {
            default: 0,
        },
        dev: {
            default: 1,
        },
        treasury: {
            default: 1,
        },
        investor: {
            default: 2,
        },
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
    mocha: {
        timeout: 200000,
    },
    networks: {
        hardhat: {
            forking: {
                enabled: true,
                url: "https://rpc.moonriver.moonbeam.network",
                blockNumber: 900000,
            },
            live: false,
            saveDeployments: true,
            tags: ["test", "local"],
        },
        moonriver: {
            url: `https://rpc.moonriver.moonbeam.network`,
            chainId: 1285,
            accounts,
            live: true,
            saveDeployments: true,
            tags: ["moonriver"],
            gasPrice: 5000000000,
            gas: 8000000,
        },
        moonbase: {
            url: `https://rpc.testnet.moonbeam.network`,
            chainId: 1287,
            accounts,
            live: true,
            saveDeployments: true,
            tags: ["moonbase"],
            gasPrice: 1000000000,
            gas: 8000000,
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.6.12",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 999999,
                    },
                },
            },
            {
                version: "0.8.2",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 999999,
                    },
                },
            },
            {
                version: "0.8.7",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 999999,
                    },
                },
            },
        ],
    },
};
