// const { WNATIVE } = require("@sushiswap/sdk");

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;
  
    const { deployer, dev } = await getNamedAccounts();

    const solarAddress = (await deployments.get("SolarBeamToken")).address;
  
    await deploy("SolarDistributor", {
      from: deployer,
      args: [solarAddress, "60000000000000000000"],
      log: true,
      deterministicDeployment: false,
    });
  };
  
  module.exports.tags = ["SolarDistributor", "Farming"];
  module.exports.dependencies = ["SolarBeamToken"];