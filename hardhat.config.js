require("dotenv/config");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
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
    defaultNetwork: "moonriver",
    namedAccounts: {
        deployer: {
            default: 0,
        },
        dev: {
            default: 1,
        },
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY,
    },
    networks: {
        moonriver: {
            url: `https://rpc.moonriver.moonbeam.network`,
            chainId: 1285,
            accounts,
            live: true,
            saveDeployments: true,
            tags: ["moonriver"],
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
        ],
    },
};
