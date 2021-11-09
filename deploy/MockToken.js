// const { WNATIVE } = require("@sushiswap/sdk");

module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;
  
    const { deployer } = await getNamedAccounts();
  
    await deploy("MockERC20", {
      from: deployer,
      args: ['MockTOKEN','TOKEN','10000000000000000000000'],
      log: true,
      deterministicDeployment: false,
    });
  };
  
  module.exports.tags = ["MockTOKEN"];