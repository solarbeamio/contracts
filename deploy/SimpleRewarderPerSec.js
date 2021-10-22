module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const mockAddress = (await deployments.get("MockERC20")).address;
    const solarAddress = (await deployments.get("SolarBeamToken")).address;
    const solarDistributorV2Address = (await deployments.get("SolarDistributorV2")).address;

    await deploy("SimpleRewarderPerSec", {
        from: deployer,
        args: [mockAddress, solarAddress, 1, solarDistributorV2Address, false],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["SimpleRewarderPerSec", "Rewarder"];
module.exports.dependencies = ["SolarDistributorV2", "SolarBeamToken", "MockERC20"];
