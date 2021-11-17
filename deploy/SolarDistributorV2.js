module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const solarToken = "0x46f79cca5350e95f30e3f17b6d35ce360bd4eaab";
    const solarPerSec = "1000000000000000000";
    const teamAddress = "0x802b46f5A855322C42240B5F6d518000560916f1";
    const treasuryAddress = "0xCFF5Ffd9a6df2b9cae36928A00cCA4957cF6B651";
    const investorAddress = "0x666Bd232f69e2dBC61c2432e3e07993b29452C37";

    await deploy("SolarDistributorV2", {
        from: deployer,
        args: [solarToken, solarPerSec, teamAddress, treasuryAddress, investorAddress, 100, 100, 100],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["SolarDistributorV2", "FarmingV2"];
