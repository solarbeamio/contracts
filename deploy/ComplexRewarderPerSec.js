module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const rewardToken = "";
    const distributorV2 = "";
    const tokenPerSec = "";

    await deploy("ComplexRewarderPerSec", {
        from: deployer,
        args: [rewardToken, tokenPerSec, distributorV2, false],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["Rewarder"];
