module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const solarAddress = (await deployments.get("SolarBeamToken")).address;

    await deploy("SolarDistributorV2", {
        from: deployer,
        args: [solarAddress, "60000000000000000000", deployer, deployer, deployer, 10, 10, 10],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["SolarDistributorV2", "FarmingV2"];
module.exports.dependencies = ["SolarBeamToken"];
