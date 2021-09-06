// const { WNATIVE } = require("@sushiswap/sdk");

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;
  
    const { deployer } = await getNamedAccounts();
  
    await deploy("SolarBeamToken", {
      from: deployer,
      args: ['0x0D0b4862F5FfA3A47D04DDf0351356d20C830460'],
      log: true,
      deterministicDeployment: false,
    });
  };
  
  module.exports.tags = ["SolarBeamToken", "ERC20"];