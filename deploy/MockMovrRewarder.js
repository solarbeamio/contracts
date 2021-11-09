module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const mockMovr = "0x579e6e41deaeed8f65768e161a0fd63d760cae5c";
    const distributorV2 = "0x3af684Db016dD0148F6Bc607b4C4d700bfA25947";

    await deploy("ComplexRewarderPerSec", {
        from: deployer,
        args: [mockMovr, "2777777777777777", distributorV2, false],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["Rewarder0"];
