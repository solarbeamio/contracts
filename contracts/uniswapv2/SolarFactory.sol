// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import './interfaces/ISolarFactory.sol';
import './SolarPair.sol';

contract SolarFactory is ISolarFactory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(SolarPair).creationCode));

    address public override feeTo;
    address public override feeToSetter;
    address public override migrator;
    address public override auro;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'SolarBeam: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SolarBeam: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'SolarBeam: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(SolarPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        SolarPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, 'SolarBeam: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, 'SolarBeam: FORBIDDEN');
        migrator = _migrator;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, 'SolarBeam: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    
    function setAuroAddress(address _auro) external override {
        require(msg.sender == feeToSetter, 'SolarBeam: FORBIDDEN');
        require(_auro != address(0), 'SolarBeam: INVALID_ADDRESS');
        auro = _auro;
    }



    function enableMetaTxnsPair(address pairAddress) external {
        require(msg.sender == feeToSetter, 'SolarBeam: FORBIDDEN');
        require(pairAddress != address(0), 'SolarBeam: PAIR_NOT_EXISTS');

        SolarPair pair = SolarPair(pairAddress);

        require(!pair.metaTxnsEnabled(), 'SolarBeam: META_TXNS_ALREADY_ENABLED');

        pair.enableMetaTxns();
    }

    function disableMetaTxnsPair(address pairAddress) external {
        require(msg.sender == feeToSetter, 'SolarBeam: FORBIDDEN');
        require(pairAddress != address(0), 'SolarBeam: PAIR_NOT_EXISTS');

        SolarPair pair = SolarPair(pairAddress);

        require(pair.metaTxnsEnabled(), 'SolarBeam: META_TXNS_ALREADY_DISABLED');

        pair.disableMetaTxns();
    }

}
