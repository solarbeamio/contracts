// const { WNATIVE } = require("@sushiswap/sdk");
require("@nomiclabs/hardhat-ethers");

module.exports = async function ({ getNamedAccounts, deployments, ethers }) {
    const { deploy } = deployments;

    const { deployer, dev } = await getNamedAccounts();

    const abi = ethers.utils.defaultAbiCoder;

    // IERC20 _lpToken,
    // IERC20 _offeringToken,
    // uint256 _startBlock,
    // uint256 _endBlock,
    // uint256 _vestingBlockOffset, // Number of Blocks to offset for each harvest period
    // uint256 _eligibilityThreshold, // (1e18)
    // address _solarVault,
    // uint256[] memory _harvestReleasePercent,
    // bytes memory _multipliers

    //   struct Multipliers {
    //     uint16[NUMBER_THRESHOLDS] poolThresholds;
    //     uint8[NUMBER_VAULT_POOLS] poolBaseMult;
    //     uint8[NUMBER_THRESHOLDS][NUMBER_VAULT_POOLS] poolMultipliers;
    // }
    // uint16[] memory thresholds,
    // uint8[] memory base,
    // uint8[][] memory mults

    const MOVRSOLAR = "0x7eDA899b3522683636746a2f3a7814e6fFca75e1";
    const PETS = "0x1e0F2A75Be02c025Bd84177765F89200c04337Da";

    const blockTime = 14.6;
    const correctEndBlock = 810960; //28th October - 12h EST
    const correctStartBlock = Math.floor(correctEndBlock - (6 * 60 * 60) / blockTime); //6h - IDO starting 6h earlier
    const blockOffset = Math.floor((30 * 24 * 60 * 60) / blockTime); //30d

    const lpToken = MOVRSOLAR;
    const offeringToken = PETS;
    const endBlock = correctEndBlock;
    const startBlock = correctStartBlock;
    const vestingBlockOffset = blockOffset;
    const eligibilityThreshold = (50 * 10 ** 18).toString();
    const solarVault = "0x7e6E03822D0077F3C417D33caeAc900Fc2645679";
    const harvestReleasePercent = [3000, 2333, 2333, 2334];
    const multipliers = abi.encode(
        ["uint16[]", "uint8[]", "uint8[][]"],
        [
            [50, 150, 500],
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

module.exports.tags = ["Eclipse"];
