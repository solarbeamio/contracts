module.exports = async function ({ getNamedAccounts, deployments }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const mockSolar = "0x46F79Cca5350E95F30e3F17b6D35CE360bd4EAAB";

    //1,000 SOLAR/DAY
    await deploy("SolarDistributorV2", {
        from: deployer,
        args: [mockSolar, "1574074074074075", deployer, deployer, deployer, 100, 100, 100],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["SolarDistributorV2", "FarmingV2"];
