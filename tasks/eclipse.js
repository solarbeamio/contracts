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

task("eclipse:getUserMultiplier", "Eclipse: Get User Multiplier").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");
    const address = "0xb152C1746543FdC63b308808497B64F52774f805";
    const e18 = BigNumber.from(10).pow(18);

    const multiplier = await eclipse.getUserMultiplier(address);
    console.log(multiplier.toString());
});

task("eclipse:viewUserAllocationPools", "Eclipse: View User Allocation Pools").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");
    const address = "0xb152C1746543FdC63b308808497B64F52774f805";
    const e18 = BigNumber.from(10).pow(18);

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     * @param _pids[]: array of pids
     * @return (uint256[] memory)
     */
    const [pool1, pool2] = await eclipse.viewUserAllocationPools(address, [0, 1]);
    console.log(pool1.toString());
    console.log(pool2.toString());
});

task("eclipse:updateStartAndEndBlocks", "Eclipse: Update Start And End Blocks").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");

    const blockTime = 14.5;
    const correctEndBlock = 810960; //28th October - 12h EST
    const correctStartBlock = Math.floor(correctEndBlock - (6 * 60 * 60) / blockTime); //6h - IDO starting 6h earlier

    console.log(`Updating StartAndEndBlocks`);
    await eclipse.updateStartAndEndBlocks(correctStartBlock, correctEndBlock);
});

task("eclipse:poolInfo", "Eclipse: Pool Info").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");

    const poolInfo = await eclipse.poolInfo(0);
    console.log(poolInfo);
});

task("mockMOVR:mint", "mockMOVR: mint").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const erc20 = await getContractFactory("MockERC20");
    const movr = await erc20.attach("0x579E6E41dEAEed8F65768E161A0FD63D760Cae5c");
    await movr.mint("0xb152C1746543FdC63b308808497B64F52774f805", "100000000000000000000000");
});

task("mockERC20:mint", "mockERC20: mint").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const erc20 = await getContractFactory("MockERC20");
    const movr = await erc20.attach("0x46F79Cca5350E95F30e3F17b6D35CE360bd4EAAB");
    await movr.mint("0xb152C1746543FdC63b308808497B64F52774f805", "4000000000000000000000000");
});

task("eclipse:enableClaim", "Eclipse: EnableClaim").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");
    await eclipse.enableClaim();
});

task("eclipse:setOfferingToken", "Eclipse: Set Offering Token").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");
    await eclipse.setOfferingToken("0x1e0F2A75Be02c025Bd84177765F89200c04337Da");
});

task("eclipse:finalWithdraw", "Eclipse: Final Withdraw").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");
    await eclipse.finalWithdraw("10000000000000000000", "0");
});

task("eclipse:getOfferingToken", "Eclipse: Get Offering Token").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const eclipse = await getContract("CommonEclipse");
    const offeringToken = await eclipse.offeringToken();
    console.log(offeringToken);
});

task("eclipse:setPoolsOfficial", "Eclipse: Set Pools").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const factory = await getContractFactory("CommonEclipse");
    const eclipse = await factory.attach("0x022Bcb66662Bb3854b6f16bAbD4c13BFa3dB0b08");

    const raise = 50000;
    const offeringPrice = 3;
    const lpPrice = 205; //REAL LP PRICE AT TIME
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

task("timelock:setAdmin", "timelock: setAdmin").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const eclipse = await getContract("Timelock");
    const offeringToken = await eclipse.admin();
    console.log(offeringToken);
});

task("timelock:queuedTransactions", "timelock: queuedTransactions").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const factory = await getContractFactory("Timelock");
    const timelock = await factory.attach("0xB256C57AA0778a184D26D3B7c033dB950c7bF007");

    const queued = await timelock.queuedTransactions("0x54c437ae2bee6177b726e46862d05190ab0b724f34a7a47c4cc15c42689d1c83");
    console.log(queued);
});

task("timelock:balance", "timelock: balance").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const factory = await getContractFactory("Timelock");
    const timelock = await factory.attach("0xB256C57AA0778a184D26D3B7c033dB950c7bF007");

    const queued = await timelock.provider.getBalance("0x16F50e8067B92F78783278139A4972adC76A15ac");
    console.log(queued.toString());
});
