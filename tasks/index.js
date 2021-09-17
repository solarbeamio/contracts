const { task } = require("hardhat/config");

task("accounts", "Prints the list of accounts", require("./accounts"));
task("gas-price", "Prints gas price").setAction(async function ({ address }, { ethers }) {
    console.log("Gas price", (await ethers.provider.getGasPrice()).toString());
});

task("bytecode", "Prints bytecode").setAction(async function ({ address }, { ethers }) {
    console.log("Bytecode", await ethers.provider.getCode(address));
});

task("feeder:feed", "Feed").setAction(async function ({ feedDev }, { getNamedAccounts, ethers: { BigNumber }, getChainId }) {
    const { deployer, dev } = await getNamedAccounts();

    const feeder = new ethers.Wallet(process.env.FEEDER_PRIVATE_KEY, ethers.provider);

    await (
        await feeder.sendTransaction({
            to: deployer,
            value: BigNumber.from(1).mul(BigNumber.from(10).pow(18)),
        })
    ).wait();
});

task("feeder:return", "Return funds to feeder").setAction(async function ({ address }, { ethers: { getNamedSigners } }) {
    const { deployer, dev } = await getNamedSigners();

    await (
        await deployer.sendTransaction({
            to: process.env.FEEDER_PUBLIC_KEY,
            value: await deployer.getBalance(),
        })
    ).wait();

    await (
        await dev.sendTransaction({
            to: process.env.FEEDER_PUBLIC_KEY,
            value: await dev.getBalance(),
        })
    ).wait();
});

task("farm:solarPerBlock", "SolarDistributor: SolarPerBlock").setAction(async function ({}, { ethers: { getNamedSigner, getContractFactory } }, runSuper) {
    const SolarDistributor = await getContractFactory("SolarDistributor");
    const solarDistributor = await SolarDistributor.attach("0xf03b75831397D4695a6b9dDdEEA0E578faa30907");
    const solarPerBlock = await solarDistributor.solarPerBlock();
    console.log(solarPerBlock.toString());
});


task("vault:add-pools", "SolarVault: Add pools").setAction(async function ({}, { ethers: { getNamedSigner, getContract } }, runSuper) {
    const farm = await getContract("SolarVault");
    const solar = "0x6bD193Ee6D2104F14F94E2cA6efefae561A4334B";

    const connectedFarm = await farm.connect(await getNamedSigner("deployer"));

    console.log(`Creating Solar [0 days lockup pool].`);
    await (await connectedFarm.add("5", solar, "0", "15", "0", false)).wait();

    console.log(`Creating Solar [7 days lockup pool].`);
    await (await connectedFarm.add("25", solar, "0", "15", "604800", false)).wait();

    console.log(`Creating Solar [30 days lockup pool].`);
    await (await connectedFarm.add("70", solar, "0", "15", "2592000", false)).wait();
});
