// const { WNATIVE } = require("@sushiswap/sdk");
require("@nomiclabs/hardhat-ethers");

module.exports = async function ({ getNamedAccounts, deployments, ethers }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const abi = ethers.utils.defaultAbiCoder;

    const MOCKMOVR = "0x579E6E41dEAEed8F65768E161A0FD63D760Cae5c";
    const MOCKPETS = "0x46F79Cca5350E95F30e3F17b6D35CE360bd4EAAB";

    const blockTime = 14.5;
    const correctStartBlock = 806160;
    const correctEndBlock = Math.floor(correctStartBlock + (7 * 60) / blockTime); //7 min
    const blockOffset = Math.floor((3 * 60) / blockTime); //3 min

    const lpToken = MOCKMOVR;
    const offeringToken = MOCKPETS;
    const endBlock = correctEndBlock;
    const startBlock = correctStartBlock;
    const vestingBlockOffset = blockOffset;
    const eligibilityThreshold = (1 * 10 ** 18).toString();
    const solarVault = "0x7e6E03822D0077F3C417D33caeAc900Fc2645679";
    const harvestReleasePercent = [3000, 2333, 2333, 2334];
    const multipliers = abi.encode(
        ["uint16[]", "uint8[]", "uint8[][]"],
        [
            [1, 2, 3],
            [1, 2, 10],
            [
                [1, 3, 10],
                [1, 3, 10],
                [1, 3, 10],
            ],
        ]
    );

    await deploy("CommonEclipse", {
        from: deployer,
        args: [lpToken, offeringToken, startBlock, endBlock, vestingBlockOffset, eligibilityThreshold, solarVault, harvestReleasePercent, multipliers],
        log: true,
        deterministicDeployment: false,
    });
};

module.exports.tags = ["EclipseTesting"];
