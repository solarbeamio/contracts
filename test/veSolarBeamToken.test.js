const { ethers } = require("hardhat");
const { expect } = require("chai");
const { latest } = require("./utils");

const splitSignatureToRSV = (signature) => {
    const r = "0x" + signature.substring(2).substring(0, 64);
    const s = "0x" + signature.substring(2).substring(64, 128);
    const v = parseInt(signature.substring(2).substring(128, 130), 16);
    return { r, s, v };
};

const signWithEthers = async (signer, fromAddress, typeData) => {
    const signerAddress = await signer.getAddress();
    if (signerAddress.toLowerCase() !== fromAddress.toLowerCase()) {
        throw new Error("Signer address does not match requested signing address");
    }

    const { EIP712Domain: _unused, ...types } = typeData.types;
    const rawSignature = await (signer.signTypedData ? signer.signTypedData(typeData.domain, types, typeData.message) : signer._signTypedData(typeData.domain, types, typeData.message));

    return splitSignatureToRSV(rawSignature);
};

describe("veSolarBeamToken", function () {
    before(async function () {
        const [owner] = await ethers.getSigners();
        this.owner = owner;
        this.signers = await ethers.getSigners();
        this.deployer = this.signers[0];
        this.bob = this.signers[1];
        this.carol = this.signers[2];
        this.dev = this.signers[3];
        this.treasury = this.signers[4];
        this.investor = this.signers[5];
        this.minter = this.signers[6];
        this.alice = this.signers[7];

        this.GasSwap = await ethers.getContractFactory("GasSwap");
        this.Router = await ethers.getContractFactory("MockRouter");
        this.ERC20 = await ethers.getContractFactory("MockERC20");
    });

    beforeEach(async function () {
        this.router = await this.Router.deploy();
        await this.router.deployed();

        this.gasSwap = await this.GasSwap.deploy(this.router.address);
        await this.gasSwap.deployed();

        this.erc20 = await this.ERC20.deploy("MockERC20", "MOCK", BigInt(10 * 1e18).toString());
        await this.erc20.deployed();
    });

    it("execute swap", async function () {});

    it("execute meta tx", async function () {});
});
