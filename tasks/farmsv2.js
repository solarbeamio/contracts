const { task } = require("hardhat/config");

const mockSolar = "0x46f79cca5350e95f30e3f17b6d35ce360bd4eaab";
const mockMovr = "0x579e6e41deaeed8f65768e161a0fd63d760cae5c";
const mockToken = "0xef5632D36ba3D98E322083bf854A21a29e777975";
const deployer = "0xb152C1746543FdC63b308808497B64F52774f805";

task("farmsv2:startFarming", "farmsv2: startFarming").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");
    await farms.startFarming();
});

task("farmsv2:add", "farmsv2: add solar pool with movr rewards").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");
    const rewarder = await getContract("ComplexRewarderPerSec");
    await farms.add("10000", mockSolar, 0, 15, [rewarder.address]);
});

task("farmsv2:set", "farmsv2: add solar pool with movr rewards").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");
    const rewarder = await getContract("ComplexRewarderPerSec");

    // uint256 _pid,
    // uint256 _allocPoint,
    // uint16 _depositFeeBP,
    // uint256 _harvestInterval,
    // IComplexRewarder[] calldata _rewarders

    await farms.set(0, "10000", 0, 15, [rewarder.address]);
});

task("farmsv2:deposit", "farmsv2: deposit").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");
    const erc20 = await getContractFactory("MockERC20");
    const solar = await erc20.attach(mockSolar);

    await solar.approve(farms.address, "1000000000000000000000000000");
    await farms.deposit(0, "100000000000000");
});

task("farmsv2:pendingTokens", "farmsv2: pendingTokens").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");
    const rewarder = await getContract("ComplexRewarderPerSec");
    // await farms.updatePool(0);
    const pendingTokens = await farms.pendingTokens(0, deployer);
    console.log(pendingTokens);
});

task("farmsv2:harvest", "farmsv2: harvest").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");
    await farms.deposit(0, 0);
});

task("farmsv2:poolInfo", "farmsv2: poolInfo").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");

    const poolinfo = await farms.poolInfo(0);
    console.log(poolinfo);
});

task("farmsv2:poolRewardsPerSec", "farmsv2: poolRewardsPerSec").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");

    const poolinfo = await farms.poolRewardsPerSec(0);
    console.log(farms.address);
    console.log(poolinfo);
});

task("rewarder:mint", "rewarder: mint MOVR").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const rewarder = await getContract("ComplexRewarderPerSec");
    const erc20 = await getContractFactory("MockERC20");
    const movr = await erc20.attach(mockMovr);
    await movr.mint(rewarder.address, "100000000000000000000000000");
});

task("rewarder:add", "rewarder: add solar pool with movr rewards").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const rewarder = await getContract("ComplexRewarderPerSec");
    await rewarder.add(0, "10000");
});

task("rewarder:updatePool", "rewarder: updatePool").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const rewarder = await getContract("ComplexRewarderPerSec");
    await (await rewarder.updatePool(0)).wait();
});

task("rewarder:info", "rewarder: info").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const rewarder = await getContract("ComplexRewarderPerSec");
    
    const totalRewards = await rewarder.totalRewards();
    console.log(totalRewards.toString());
    const totalDebt = await rewarder.totalDebt();
    console.log(totalDebt.toString());
    const totalDebtPaid = await rewarder.totalDebtPaid();
    console.log(totalDebtPaid.toString());

    const balance = await rewarder.balance();
    console.log(balance.toString());
    const pendingBalance = await rewarder.pendingBalance();
    console.log(pendingBalance.toString());
});

task("rewarder:setRewardRate", "rewarder: set reward rate").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const rewarder = await getContract("ComplexRewarderPerSec");
    await (await rewarder.setRewardRate("2777777777777776")).wait();
});

task("farmsv2:setRewarders", "farmsv2: add solar pool with movr rewards").setAction(async function ({}, { ethers: { getContract, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");
    await farms.set(0, "10000", 0, 15, ["0x4432284D2F9B6152ae542f4587B00c23C255894e", "0x8d677987B5746707b080A3FD856B0a327C92f0de"]);
});

task("farmsv2:init", "farmsv2: init").setAction(async function ({}, { ethers: { getContract, getContractFactory, BigNumber } }) {
    const farms = await getContract("SolarDistributorV2");
    const rewarder = await getContract("ComplexRewarderPerSec");
    const erc20 = await getContractFactory("MockERC20");
    const movr = await erc20.attach(mockMovr);
    const solar = await erc20.attach(mockSolar);

    await (await farms.add("10000", mockSolar, 0, 15, [rewarder.address])).wait();

    await (await movr.mint(deployer, "1000000000000000000")).wait();
    await (await movr.approve(rewarder.address, "1000000000000000000")).wait();
    await (await rewarder.depositRewards("1000000000000000000")).wait();

    await (await rewarder.add(0, "10000")).wait();
    await (await solar.mint(deployer, "100000000000000000000")).wait();
    await (await solar.approve(farms.address, "1000000000000000000000000000")).wait();

    await (await farms.startFarming()).wait();
    await (await farms.deposit(0, "1000000000000000000")).wait();
});
