module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const solarToken = "0x6bD193Ee6D2104F14F94E2cA6efefae561A4334B";
    const solarPerSec = "";
    const teamAddress = "";
    const treasuryAddress = "";
    const investorAddress = "";

    await deploy("SolarDistributorV2", {
        from: deployer,
        args: [solarToken, solarPerSec, teamAddress, treasuryAddress, investorAddress, 100, 100, 100],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["SolarDistributorV2", "FarmingV2"];
