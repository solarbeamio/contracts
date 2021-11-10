const { task } = require("hardhat/config");

task("eclipse:setPools", "Eclipse: Set Pools").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");

    const raise = 5000;
    const offeringPrice = 3;
    const lpPrice = 1; //REAL LP PRICE AT TIME
    const base = 100;
    const e18 = BigNumber.from(10).pow(18);

    const totalRaiseLP = BigNumber.from(raise).mul(e18).div(lpPrice);
    const offeringAmount = BigNumber.from(raise).mul(e18).mul(10).div(offeringPrice);
    const baseLimit = BigNumber.from(base).mul(e18).div(lpPrice);

    // * @param _raisingAmount: amount of LP token the pool aims to raise (1e18)
    // * @param _offeringAmount: amount of IDO tokens the pool is offering (1e18)
    // * @param _baseLimitInLP: base limit of tokens per eligible user (if 0, it is ignored) (1e18)
    // * @param _hasTax: true if a pool is to be taxed on overflow
    // * @param _pid: pool identification number

    console.log(`Setting Pool 0 - Basic Sale`);
    await eclipse.setPool(totalRaiseLP, offeringAmount, baseLimit, false, 0);

    console.log(`Setting Pool 1 - Unlimited Sale`);
    await eclipse.setPool(totalRaiseLP, offeringAmount, 0, true, 1);
});

task("eclipse:setMultipliers", "Eclipse: Set Multipliers").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");

    const abi = ethers.utils.defaultAbiCoder;

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

    console.log(`Setting Multipliers`);
    await eclipse.setMultipliers(multipliers);
});

task("eclipse:updateStartAndEndBlocks", "Eclipse: Update Start And End Blocks").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");

    const blockTime = 14.5;
    const correctEndBlock = 810960; //28th October - 12h EST
    const correctStartBlock = Math.floor(correctEndBlock - (6 * 60 * 60) / blockTime); //6h - IDO starting 6h earlier

    console.log(`Updating StartAndEndBlocks`);
    await eclipse.updateStartAndEndBlocks(correctStartBlock, correctEndBlock);
});

task("eclipse:enableClaim", "Eclipse: EnableClaim").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");
    await eclipse.enableClaim();
});

task("eclipse:setOfferingToken", "Eclipse: Set Offering Token").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");
    await eclipse.setOfferingToken("0x1e0F2A75Be02c025Bd84177765F89200c04337Da");
});

task("eclipse:setPoolsFinal", "Eclipse: Set Pools").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const factory = await getContractFactory("CommonEclipse");
    const eclipse = await factory.attach("0x022Bcb66662Bb3854b6f16bAbD4c13BFa3dB0b08");

    const raise = 50000;
    const offeringPrice = 3;
    const lpPrice = 205;
    const base = 100;
    const e18 = BigNumber.from(10).pow(18);

    const totalRaiseLP = BigNumber.from(raise).mul(e18).div(lpPrice);
    const offeringAmount = BigNumber.from(raise).mul(e18).mul(10).div(offeringPrice);
    const baseLimit = BigNumber.from(base).mul(e18).div(lpPrice);

    // * @param _raisingAmount: amount of LP token the pool aims to raise (1e18)
    // * @param _offeringAmount: amount of IDO tokens the pool is offering (1e18)
    // * @param _baseLimitInLP: base limit of tokens per eligible user (if 0, it is ignored) (1e18)
    // * @param _hasTax: true if a pool is to be taxed on overflow
    // * @param _pid: pool identification number

    console.log(`Setting Pool 0 - Basic Sale`);
    await eclipse.setPool(totalRaiseLP, offeringAmount, baseLimit, false, 0);

    console.log(`Setting Pool 1 - Unlimited Sale`);
    await eclipse.setPool(totalRaiseLP, offeringAmount, 0, true, 1);
});
