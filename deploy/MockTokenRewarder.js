module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const mockToken = "0xef5632D36ba3D98E322083bf854A21a29e777975";
    const distributorV2 = "0x4247172C77d5618637acCC1388d1A217A1461Eff";

    // IBoringERC20 _rewardToken,
    // uint256 _tokenPerSec,
    // ISolarDistributorV2 _distributorV2,
    // bool _isNative

    await deploy("ComplexRewarderPerSec", {
        from: deployer,
        args: [mockToken, "416666666666666666", distributorV2, false],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["Rewarder1"];
