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

describe("GasSwap", function () {
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

    it("execute swap", async function () {
        const { chainId } = await ethers.provider.getNetwork();
        const erc20nounce = await this.erc20.nonces(this.deployer.address);
        const lastTimestamp = await latest();

        const balance = await this.erc20.balanceOf(this.deployer.address);

        const permitInfo = {
            version: "1",
            name: "MockERC20",
        };

        const domain = {
            name: permitInfo.name,
            version: permitInfo.version,
            verifyingContract: this.erc20.address,
            chainId,
        };

        const EIP2612_TYPE = [
            { name: "owner", type: "address" },
            { name: "spender", type: "address" },
            { name: "value", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" },
        ];

        const EIP712_DOMAIN_TYPE = [
            { name: "name", type: "string" },
            { name: "version", type: "string" },
            { name: "chainId", type: "uint256" },
            { name: "verifyingContract", type: "address" },
        ];

        const deadline = lastTimestamp.add(60 * 30);

        const message = {
            owner: this.deployer.address,
            spender: this.gasSwap.address,
            value: balance,
            nonce: erc20nounce,
            deadline: deadline,
        };

        const data = {
            types: {
                EIP712Domain: EIP712_DOMAIN_TYPE,
                Permit: EIP2612_TYPE,
            },
            domain,
            primaryType: "Permit",
            message,
        };

        const { r, s, v } = await signWithEthers(this.deployer, this.deployer.address, data);

        const swapCallData = ethers.utils.defaultAbiCoder.encode(["uint256", "uint256", "address[]", "address", "uint256", "uint8", "bytes32", "bytes32"], [balance, 0, [this.erc20.address, "0x98878B06940aE243284CA214f92Bb71a2b032B8A"], this.deployer.address, deadline, v, r, s]);

        await this.gasSwap.whitelistToken(this.erc20.address, true);

        await this.gasSwap.swap(swapCallData);

        const balanceAfterSwap = await this.erc20.balanceOf(this.deployer.address);

        expect(balanceAfterSwap).to.equal(0);
    });

    it("execute meta tx", async function () {
        const { chainId } = await ethers.provider.getNetwork();
        const erc20nounce = await this.erc20.nonces(this.deployer.address);
        const lastTimestamp = await latest();

        const permitInfo = {
            version: "1",
            name: "MockERC20",
        };

        const domain = {
            name: permitInfo.name,
            version: permitInfo.version,
            verifyingContract: this.erc20.address,
            chainId,
        };

        const EIP2612_TYPE = [
            { name: "owner", type: "address" },
            { name: "spender", type: "address" },
            { name: "value", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" },
        ];

        const EIP712_DOMAIN_TYPE = [
            { name: "name", type: "string" },
            { name: "version", type: "string" },
            { name: "chainId", type: "uint256" },
            { name: "verifyingContract", type: "address" },
        ];

        const deadline = lastTimestamp.add(60 * 30);

        const message = {
            owner: this.deployer.address,
            spender: this.gasSwap.address,
            value: BigInt(10 * 1e18).toString(),
            nonce: erc20nounce,
            deadline: deadline,
        };

        const data = {
            types: {
                EIP712Domain: EIP712_DOMAIN_TYPE,
                Permit: EIP2612_TYPE,
            },
            domain,
            primaryType: "Permit",
            message,
        };

        const { r, s, v } = await signWithEthers(this.deployer, this.deployer.address, data);

        const swapCallData = ethers.utils.defaultAbiCoder.encode(["uint256", "uint256", "address[]", "address", "uint256", "uint8", "bytes32", "bytes32"], [BigInt(10 * 1e18).toString(), 0, [this.erc20.address, "0x98878B06940aE243284CA214f92Bb71a2b032B8A"], this.deployer.address, deadline, v, r, s]);

        //// META DATA

        // Initialize Constants
        const domainType = [
            { name: "name", type: "string" },
            { name: "version", type: "string" },
            { name: "verifyingContract", type: "address" },
            { name: "salt", type: "bytes32" },
        ];

        const metaTransactionType = [
            { name: "nonce", type: "uint256" },
            { name: "from", type: "address" },
            { name: "functionSignature", type: "bytes" },
        ];

        const domainData = {
            name: "GasSwap",
            version: "2",
            verifyingContract: this.gasSwap.address,
            salt: ethers.utils.hexZeroPad(ethers.BigNumber.from(chainId).toHexString(), 32),
        };

        const nonce = await this.gasSwap.getNonce(this.deployer.address);

        const functionSignature = this.gasSwap.interface.encodeFunctionData("swap", [swapCallData]);

        const metaMessage = {
            nonce: parseInt(nonce),
            from: this.deployer.address,
            functionSignature: functionSignature,
        };

        const metaDataToSign = {
            types: {
                EIP712Domain: domainType,
                MetaTransaction: metaTransactionType,
            },
            domain: domainData,
            primaryType: "MetaTransaction",
            message: metaMessage,
        };

        const { r: metaR, s: metaS, v: metaV } = await signWithEthers(this.deployer, this.deployer.address, metaDataToSign);

        await this.gasSwap.whitelistToken(this.erc20.address, true);

        await this.gasSwap.executeMetaTransaction(this.deployer.address, functionSignature, metaR, metaS, metaV);

        const balanceAfterSwap = await this.erc20.balanceOf(this.deployer.address);

        expect(balanceAfterSwap).to.equal(0);
    });
});
