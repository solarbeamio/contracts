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

task("vault:fixAllocs", "SolarVault: Start").setAction(async function ({}, { ethers: { getNamedSigner, getContract, getContractFactory } }, runSuper) {
    const SolarDistributor = await getContractFactory("SolarDistributor");
    const solarDistributor = await SolarDistributor.attach("0xf03b75831397D4695a6b9dDdEEA0E578faa30907");
    const connectedDistributor = await solarDistributor.connect(await getNamedSigner("deployer"));

    // const SolarBeamToken = await getContractFactory("SolarBeamToken");
    // const solarBeamToken = await SolarBeamToken.attach("0x6bD193Ee6D2104F14F94E2cA6efefae561A4334B");
    // const connectedSolar = await solarBeamToken.connect(await getNamedSigner("deployer"));

    // console.log(`Give minter role to Vault`);
    // await connectedSolar.grantRole('0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6', '0x7e6E03822D0077F3C417D33caeAc900Fc2645679'); //Grant role

    // const vault = await getContract("SolarVault");
    // const connectedVault = await vault.connect(await getNamedSigner("deployer"));

    console.log(`Fixing pools allocation`);
    // await (await connectedDistributor.updateAllocPoint("0", "6000", false)).wait(); //MOVR/SOLAR
    // await connectedDistributor.updateAllocPoint("1", "0", false); //SOLAR
    // await connectedDistributor.updateAllocPoint("2", "370", false); //MOVR
    // await connectedDistributor.updateAllocPoint("3", "80", false); //RIB/SOLAR
    // await connectedDistributor.updateAllocPoint("4", "90", false); //RIB/MOVR
    // await connectedDistributor.updateAllocPoint("5", "25", false); //RIB
    // await connectedDistributor.updateAllocPoint('6', '600', false);  //USDC/MOVR
    // await connectedDistributor.updateAllocPoint('7', '2300', false); //USDC/SOLAR
    // await connectedDistributor.updateAllocPoint('8', '270', false);  //USDC/DAI
    // await connectedDistributor.updateAllocPoint('9', '270', false);  //USDC/BUSD
    // await connectedDistributor.updateAllocPoint('10', '270', false); //ETH/USDC
    // await connectedDistributor.updateAllocPoint('11', '270', false); //BNB/BUSD
    // await connectedDistributor.updateAllocPoint('12', '135', false); //MATIC/MOVR
    // await connectedDistributor.updateAllocPoint('13', '135', false); //AVAX/MOVR
    // await connectedDistributor.updateAllocPoint('14', '90', false); //RELAY/MOVR

    // console.log(`Vault: Fix single pool`);
    // await connectedVault.updateAllocPoint("0", "10", false); //SOLAR 0d

    // console.log(`Distributor: UpdateEmissionRate to 3.95/block`);
    // await connectedDistributor.updateEmissionRate("3950000000000000000");

    // console.log(`Vault: UpdateEmissionRate to 1.05/block`);
    // await connectedVault.updateEmissionRate("1050000000000000000");
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

task("farm:add-pools", "Farm: Add pools").setAction(async function ({}, { ethers: { getNamedSigner, getContract, getContractFactory } }, runSuper) {
    const SolarDistributor = await getContractFactory("SolarDistributor");
    const solarDistributor = await SolarDistributor.attach("0xf03b75831397D4695a6b9dDdEEA0E578faa30907");
    const connectedFarm = await solarDistributor.connect(await getNamedSigner("deployer"));

    // //MATIC/MOVR
    // await (await connectedFarm.add("135", "0x29633cc367AbD9b16d327Adaf6c3538b6e97f6C0", "0", "15", false)).wait();

    // //AVAX/MOVR
    // await (await connectedFarm.add("135", "0xb9a61ac826196AbC69A3C66ad77c563D6C5bdD7b", "0", "15", false)).wait();

    // //RELAY/MOVR
    // await (await connectedFarm.add("90", "0x9e0d90ebB44c22303Ee3d331c0e4a19667012433", "0", "15", false)).wait();
});

task("token:gib-role", "token: gib role to distributor v2").setAction(async function ({}, { ethers: { getNamedSigner, getContract, getContractFactory } }, runSuper) {
    const SolarBeamToken = await getContract("SolarBeamToken");
    const SolarDistributorV2 = await getContract("SolarDistributorV2");
    const MockERC20 = await getContract("MockERC20");
    const SimpleRewarderPerSec = await getContract("SimpleRewarderPerSec");

    const MINTER_ROLE = await SolarBeamToken.MINTER_ROLE();

    // console.log("Grant Minter Role to " + SolarDistributorV2.address);
    // await SolarBeamToken.grantRole(MINTER_ROLE, SolarDistributorV2.address);

    // console.log("Add Pool " + SolarDistributorV2.address);
    // await SolarDistributorV2.add(1, SolarBeamToken.address, 0, 15, [SimpleRewarderPerSec.address]);

    // console.log("Start Farming");
    // await SolarDistributorV2.startFarming();

    const pool = await SolarDistributorV2.poolInfo(0);
    console.log(pool.rewarders);

    // //MATIC/MOVR
    // await (await connectedFarm.add("135", "0x29633cc367AbD9b16d327Adaf6c3538b6e97f6C0", "0", "15", false)).wait();

    // //AVAX/MOVR
    // await (await connectedFarm.add("135", "0xb9a61ac826196AbC69A3C66ad77c563D6C5bdD7b", "0", "15", false)).wait();

    // //RELAY/MOVR
    // await (await connectedFarm.add("90", "0x9e0d90ebB44c22303Ee3d331c0e4a19667012433", "0", "15", false)).wait();
});
