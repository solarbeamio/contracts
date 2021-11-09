// const { WNATIVE } = require("@sushiswap/sdk");

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;

    const { deployer } = await getNamedAccounts();

    await deploy("Timelock", {
        from: deployer,
        args: [deployer, 21600],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["Timelock"];

//npx hardhat verify --network moonriver 0xB256C57AA0778a184D26D3B7c033dB950c7bF007 "0xf884c8774b09b3302f98e38C944eB352264024F8", 43200
