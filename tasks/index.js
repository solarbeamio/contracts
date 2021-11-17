const { task } = require("hardhat/config");
require("./eclipse");
require("./farms");
require("./burner");

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
