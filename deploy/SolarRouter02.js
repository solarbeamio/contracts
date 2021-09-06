module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  let wethAddress = "0x98878B06940aE243284CA214f92Bb71a2b032B8A";

  const factoryAddress = (await deployments.get("SolarFactory")).address;

  await deploy("SolarRouter02", {
    from: deployer,
    args: [factoryAddress, wethAddress],
    log: true,
    deterministicDeployment: false,
  });
};

module.exports.tags = ["SolarRouter02", "AMM"];
module.exports.dependencies = ["SolarFactory"];

