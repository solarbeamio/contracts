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
                url: "https://ropsten.infura.io/v3/249b95cec9c541bf94a4333cc77e9b71",
            },
            live: false,
            saveDeployments: true,
            tags: ["test", "local"],
        },
        mainnet: {
            url: `https://mainnet.infura.io/v3/249b95cec9c541bf94a4333cc77e9b71`,
            chainId: 1,
            accounts,
            live: true,
            saveDeployments: false,
            tags: ["mainnet"],
            gasPrice: 5000000000,
            gas: 8000000,
        },
        rinkeby: {
            url: `https://rinkeby.infura.io/v3/249b95cec9c541bf94a4333cc77e9b71`,
            chainId: 4,
            accounts,
            live: true,
            saveDeployments: false,
            tags: ["rinkeby"],
            gasPrice: 5000000000,
            gas: 8000000,
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
        compilers: [{
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