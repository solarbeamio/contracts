const { ethers } = require("hardhat");
const { BigNumber } = ethers;

const disableAutomine = async function () {
    return ethers.provider.send("evm_setAutomine", [false]);
};

const advanceBlock = async function () {
    return ethers.provider.send("evm_mine", []);
};

const advanceBlockTo = async function (blockNumber) {
    for (let i = await ethers.provider.getBlockNumber(); i < blockNumber; i++) {
        await advanceBlock();
    }
};

const increase = async function (value) {
    await ethers.provider.send("evm_increaseTime", [value.toNumber()]);
    await advanceBlock();
};

const latest = async function () {
    const block = await ethers.provider.getBlock("latest");
    return BigNumber.from(block.timestamp);
};

const advanceTimeAndBlock = async function (time) {
    await advanceTime(time);
    await advanceBlock();
};

const advanceTime = async function (time) {
    await ethers.provider.send("evm_increaseTime", [time]);
};

const duration = {
    seconds: function (val) {
        return BigNumber.from(val);
    },
    minutes: function (val) {
        return BigNumber.from(val).mul(this.seconds("60"));
    },
    hours: function (val) {
        return BigNumber.from(val).mul(this.minutes("60"));
    },
    days: function (val) {
        return BigNumber.from(val).mul(this.hours("24"));
    },
    weeks: function (val) {
        return BigNumber.from(val).mul(this.days("7"));
    },
    years: function (val) {
        return BigNumber.from(val).mul(this.days("365"));
    },
};

module.exports = {
    advanceBlock,
    advanceBlockTo,
    increase,
    latest,
    advanceTimeAndBlock,
    advanceTime,
    disableAutomine,
};
