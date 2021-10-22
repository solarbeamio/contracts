// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ICommonEclipse.sol";
import "../farm/SolarVault.sol";

contract CommonEclipse is ICommonEclipse, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

// NOTES
// We have to transfer Ownership in constructor!

    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC20 lpToken;
    IERC20 offeringToken;

    SolarVault public vault;

    uint8 constant public HARVEST_PERIODS = 4;

    uint256[HARVEST_PERIODS] public harvestReleaseBlocks;

    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public eligibilityThreshold;

    /**
     * @dev The uint256 stores the pools overall multiplier and
     * the arrays store additional multipliers based on staked amounts
     */
    struct Multipliers {
        uint8 zeroDayPool;
        uint8 sevenDayPool;
        uint8 thirtyDayPool;
        uint8[2][3] zeroDayMultipliers;
        uint8[2][3] sevenDayMultipliers;
        uint8[2][3] thirtyDayMultipliers;
    }

    struct UserInfo {
        uint256 amount; // How many tokens the user has provided for pool
        uint256 allocPoints; // Used to weight user allocation based on amount locked in solar vaults
        bool[HARVEST_PERIODS] claimed; // Whether the user has claimed (default: false) for pool
        bool isRefunded;
    }

    struct PoolInfo {
        uint256 raisingAmount; // amount of tokens raised for the pool (in LP tokens)
        uint256 offeringAmount; // amount of tokens offered for the pool (in offeringTokens)
        uint256 baseLimitInLP; // base limit of tokens per eligible user (if 0, it is ignored)
        bool hasTax;
        uint256 totalAmountPool; // total amount pool deposited (in LP tokens)
        uint256 sumTaxesOverflow; // total taxes collected (starts at 0, increases with each harvest if overflow)
        uint256 totalAllocPoints; // 1e12 ?
    }

    uint8 public constant numberPools = 2;

    mapping(address => mapping(uint8 => UserInfo)) public userInfo;

    PoolInfo[numberPools] public poolInfo;

   Multipliers private _multiplierInfo;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed user, uint256 amount, uint256 indexed pid);
    event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event PoolParametersSet(uint256 offeringAmount, uint256 raisingAmount, uint8 pid);
    event MultiplierParametersSet(
        uint8 zeroDayPool,
        uint8 sevenDayPool,
        uint8 thirtyDayPool,
        uint8[2][3] zeroDayMultipliers,
        uint8[2][3] sevenDayMultipliers,
        uint8[2][3] thirtyDayMultipliers
        );
    event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken);
    event AdminTokenRecovery(address token, uint256 amount);
    /*///////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyWhenActive() {
        require(
            block.number >= startBlock && block.number < endBlock,
            "Sale not active"
        );
        _;
    }
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 _lpToken,
        IERC20 _offeringToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _vestingBlockOffset, // Number of Blocks to offset for each harvest period
        uint256 _eligibilityThreshold,
        address _solarVault,
        bytes memory _multipliers
    ){
        require(_lpToken.totalSupply() >= 0);
        require(_offeringToken.totalSupply() >= 0);
        require(_lpToken != _offeringToken, "Tokens must be different");

        lpToken = _lpToken;
        offeringToken = _offeringToken;
        startBlock = _startBlock;
        endBlock = _endBlock;
        eligibilityThreshold = _eligibilityThreshold;
        vault = SolarVault(_solarVault);

        (
            uint8 _zeroDayPool,
            uint8 _sevenDayPool,
            uint8 _thirtyDayPool,
            uint8[2][3] memory _zeroDayMultipliers,
            uint8[2][3] memory _sevenDayMultipliers,
            uint8[2][3] memory _thirtyDayMultipliers

            ) = abi.decode(_multipliers,(
                uint8,
                uint8,
                uint8,
                uint8[2][3],
                uint8[2][3],
                uint8[2][3]
            ));

        _multiplierInfo.zeroDayPool = _zeroDayPool;
        _multiplierInfo.sevenDayPool = _sevenDayPool;
        _multiplierInfo.thirtyDayPool = _thirtyDayPool;
        _multiplierInfo.zeroDayMultipliers = _zeroDayMultipliers;
        _multiplierInfo.sevenDayMultipliers = _sevenDayMultipliers;
        _multiplierInfo.thirtyDayMultipliers = _thirtyDayMultipliers;

        for (uint256 i = 0; i < HARVEST_PERIODS; i++) {
            harvestReleaseBlocks[i] = endBlock + (_vestingBlockOffset * i);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            POOL MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    function setEligibilityThreshold(uint256 _eligibilityThreshold) public override onlyOwner {
        require(block.number < startBlock, "sale is already active");
        eligibilityThreshold = _eligibilityThreshold;
    }

    function setMulitpliers(bytes memory _multipliers) public override onlyOwner {
        require(block.number < startBlock, "sale is already active");
        (
            uint8 _zeroDayPool,
            uint8 _sevenDayPool,
            uint8 _thirtyDayPool,
            uint8[2][3] memory _zeroDayMultipliers,
            uint8[2][3] memory _sevenDayMultipliers,
            uint8[2][3] memory _thirtyDayMultipliers

            ) = abi.decode(_multipliers,(
                uint8,
                uint8,
                uint8,
                uint8[2][3],
                uint8[2][3],
                uint8[2][3]
            ));

        _multiplierInfo.zeroDayPool = _zeroDayPool;
        _multiplierInfo.sevenDayPool = _sevenDayPool;
        _multiplierInfo.thirtyDayPool = _thirtyDayPool;
        _multiplierInfo.zeroDayMultipliers = _zeroDayMultipliers;
        _multiplierInfo.sevenDayMultipliers = _sevenDayMultipliers;
        _multiplierInfo.thirtyDayMultipliers = _thirtyDayMultipliers;

        emit MultiplierParametersSet(
            _zeroDayPool,
            _sevenDayPool,
            _thirtyDayPool,
            _zeroDayMultipliers,
            _sevenDayMultipliers,
            _thirtyDayMultipliers
        );
    }


    function setPool(
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        uint256 _baseLimitInLP,
        bool _hasTax,
        uint8 _pid
    ) external override onlyOwner{
        require(block.number < startBlock, "sale is already active");
        require(_pid < numberPools, "pool does not exist");

        poolInfo[_pid].offeringAmount = _offeringAmount;
        poolInfo[_pid].raisingAmount = _raisingAmount;
        poolInfo[_pid].baseLimitInLP = _baseLimitInLP;
        poolInfo[_pid].hasTax = _hasTax;

        emit PoolParametersSet(_offeringAmount, _raisingAmount, _pid);
    }

    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external override onlyOwner {
        require(block.number < startBlock, "sale is already active");
        require(_startBlock < _endBlock, "mew startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        endBlock = _endBlock;

        emit NewStartAndEndBlocks(_startBlock, _endBlock);
    }

    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) external override onlyOwner {
        require(_lpAmount <= lpToken.balanceOf(address(this)), "Not enough LP tokens");
        require(_offerAmount <= offeringToken.balanceOf(address(this)), "Not enough offering token");

        if (_lpAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), _lpAmount);
        }

        if (_offerAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), _offerAmount);
        }

        emit AdminWithdraw(_lpAmount, _offerAmount);
    }

    function sweep(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(
            _tokenAddress != address(lpToken) && _tokenAddress != address(offeringToken),
            "Cannot be LP or Offering token"
        );
        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _amount);

        emit AdminTokenRecovery(_tokenAddress, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            DEPOSIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function depositPool(uint256 _amount, uint8 _pid) external override nonReentrant onlyWhenActive {
        UserInfo storage user = userInfo[msg.sender][_pid];

        require(_pid < numberPools, "pool does not exist");

        require(
            poolInfo[_pid].offeringAmount > 0 && poolInfo[_pid].raisingAmount > 0,
            "Pool not set"
        );

        for (uint256 i=0; i<3; i++) {
            vault.deposit(i,0);
        }
        (bool success) = _getEligibility();
        require(success, "user not eligible");

        lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        user.amount += _amount;


        if (poolInfo[_pid].baseLimitInLP > 0) {
            (uint8 multiplier, )=_getUserMultiplier();
            require(
                poolInfo[_pid].baseLimitInLP * multiplier <= user.amount, "New amount above user limit"
            );
        } else {
            (uint8 multiplier, uint256 staked )=_getUserMultiplier();
            poolInfo[_pid].totalAllocPoints -= userInfo[msg.sender][_pid].allocPoints;
            userInfo[msg.sender][_pid].allocPoints = staked * multiplier;
            poolInfo[_pid].totalAllocPoints += userInfo[msg.sender][_pid].allocPoints;
        }

        poolInfo[_pid].totalAmountPool += _amount;

        emit Deposit(msg.sender,_amount,_pid);

    }

    function _getEligibility() internal view returns(bool) {
        uint256 amount;
        bool isEligible;

        for (uint256 i=0; i<3; i++) {
            (amount,,,,) = vault.userInfo(i,msg.sender);
            if(amount > eligibilityThreshold) {
                isEligible = true;
            }
        }
        return isEligible;

    }

    function _getUserMultiplier() internal view returns(uint8,uint256) {
        uint256 amount;
        uint256 staked;
        uint8 mult;
        uint8 _mult;

        uint8[3] memory poolMultiplier = [
            _multiplierInfo.zeroDayPool,
            _multiplierInfo.sevenDayPool,
            _multiplierInfo.thirtyDayPool
            ];
        uint8[2][3][3] memory stakedToMultiplier = [
            _multiplierInfo.zeroDayMultipliers,
            _multiplierInfo.sevenDayMultipliers,
            _multiplierInfo.thirtyDayMultipliers
            ];

        for (uint8 i=0; i<3; i++) {
            (amount,,,,) = vault.userInfo(i,msg.sender);
            for (uint8 j=0; j<3; j++) {
                _mult = poolMultiplier[i] * stakedToMultiplier[i][j][1];
                if(amount >= (stakedToMultiplier[i][j][0]*1e18) && _mult > mult) {
                    mult = _mult;
                    staked = amount;
                }
            }
        }
        return (mult,staked);


    }

    /*///////////////////////////////////////////////////////////////
                            HARVEST LOGIC
    //////////////////////////////////////////////////////////////*/

    function harvestPool(uint8 _pid, uint8 _harvestPeriod) external override nonReentrant {
        require(_pid < numberPools, "pool does not exist");
        require(_harvestPeriod < HARVEST_PERIODS, "harvest period out of range");
        require(block.number > harvestReleaseBlocks[_harvestPeriod], "not harvest time");
        require(userInfo[msg.sender][_pid].amount > 0, "did not participate");
        require(!userInfo[msg.sender][_pid].claimed[_harvestPeriod], "harvest for period already claimed");

        userInfo[msg.sender][_pid].claimed[_harvestPeriod] = true;

        uint256 offeringTokenAmount;
        uint256 refundingTokenAmount;
        uint256 userTaxOverflow;

        (offeringTokenAmount, refundingTokenAmount, userTaxOverflow) = _calcOfferingAndRefundingAmounts(
            msg.sender,
            _pid
        );

        if (userTaxOverflow > 0) {
            poolInfo[_pid].sumTaxesOverflow += userTaxOverflow;
        }

        if (refundingTokenAmount > 0 && !userInfo[msg.sender][_pid].isRefunded) {
            userInfo[msg.sender][_pid].isRefunded = true;
            lpToken.safeTransfer(address(msg.sender), refundingTokenAmount);
        }

        uint256 offeringTokenAmountPerPeriod;
        if (offeringTokenAmount > 0) {
            offeringTokenAmountPerPeriod = offeringTokenAmount / HARVEST_PERIODS;
            lpToken.safeTransfer(address(msg.sender), offeringTokenAmountPerPeriod);
        }
        userInfo[msg.sender][_pid].claimed[_harvestPeriod] = true;

        emit Harvest(msg.sender, offeringTokenAmountPerPeriod, refundingTokenAmount,_pid);


    }

    function _calcOfferingAndRefundingAmounts(address _user, uint8 _pid)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 userOfferingAmount;
        uint256 userRefundingAmount;
        uint256 taxAmount;

        if (poolInfo[_pid].totalAmountPool > poolInfo[_pid].raisingAmount) {
            uint256 allocation = _getUserAllocation(_user,_pid);

            userOfferingAmount = poolInfo[_pid].offeringAmount * allocation / 1e12;

            uint256 payAmount = poolInfo[_pid].raisingAmount * allocation / 1e12;

            userRefundingAmount = userInfo[_user][_pid].amount - payAmount;

            if (poolInfo[_pid].hasTax) {
                uint256 taxOverflow =
                    _calculateTaxOverflow(
                        poolInfo[_pid].totalAmountPool,
                        poolInfo[_pid].raisingAmount
                    );
                taxAmount = userRefundingAmount * taxOverflow / 1e12;

                userRefundingAmount -= taxAmount;
            }
        } else {
            userRefundingAmount = 0;
            taxAmount = 0;
            if (poolInfo[_pid].baseLimitInLP > 0) {
                userOfferingAmount = userInfo[_user][_pid].amount * poolInfo[_pid].offeringAmount / poolInfo[_pid].raisingAmount;
            }
        }
        return (userOfferingAmount, userRefundingAmount, taxAmount);
    }
    /**
     * @notice It returns the user allocation for pool
     * @dev (1e12) 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _user: user address
     * @param _pid: pool id
     * @return it returns the user's share of pool
     */
    function _getUserAllocation(address _user, uint8 _pid) internal view returns (uint256) {
        if (poolInfo[_pid].totalAmountPool > 0) {
            if(poolInfo[_pid].baseLimitInLP > 0) {
                return userInfo[_user][_pid].amount * 1e18 / poolInfo[_pid].totalAmountPool * 1e6;
            } else {
                return userInfo[_user][_pid].allocPoints * 1e18 / poolInfo[_pid].totalAllocPoints / poolInfo[_pid].totalAmountPool * 1e6;
            }
        } else {
            return 0;
        }
    }

    /**
     * @notice It calculates the tax overflow given the raisingAmountPool and the totalAmountPool.
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @return It returns the tax percentage
     */
    function _calculateTaxOverflow(uint256 _totalAmountPool, uint256 _raisingAmountPool)
        internal
        pure
        returns (uint256)
    {
        uint256 ratioOverflow = _totalAmountPool / _raisingAmountPool;

        if (ratioOverflow >= 500) {
            return 2000000000; // 0.2%
        } else if (ratioOverflow >= 250) {
            return 2500000000; // 0.25%
        } else if (ratioOverflow >= 100) {
            return 3000000000; // 0.3%
        } else if (ratioOverflow >= 50) {
            return 5000000000; // 0.5%
        } else {
            return 10000000000; // 1%
        }
    }

    /*///////////////////////////////////////////////////////////////
                            PUBLIC GETTERS
    //////////////////////////////////////////////////////////////*/
    function hasHarvested(address _user, uint8 _pid, uint8 _harvestPeriod) public view returns (bool) {
        return userInfo[_user][_pid].claimed[_harvestPeriod];
    }

    /**
     * @notice It returns the tax overflow rate calculated for a pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _pid: poolId
     * @return It returns the tax percentage
     */
    function viewPoolTaxRateOverflow(uint256 _pid) external view override returns (uint256) {
        if (!poolInfo[_pid].hasTax) {
            return 0;
        } else {
            return
                _calculateTaxOverflow(poolInfo[_pid].totalAmountPool, poolInfo[_pid].raisingAmount);
        }
    }

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     * @param _pids[]: array of pids
     * @return
     */
    function viewUserAllocationPools(address _user, uint8[] calldata _pids)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory allocationPools = new uint256[](_pids.length);
        for (uint8 i = 0; i < _pids.length; i++) {
            allocationPools[i] = _getUserAllocation(_user, _pids[i]);
        }
        return allocationPools;
    }

    /**
     * @notice External view function to see user offering and refunding amounts for both pools
     * @param _user: user address
     * @param _pids: array of pids
     */
    function viewUserOfferingAndRefundingAmountsForPools(address _user, uint8[] calldata _pids)
        external
        view
        override
        returns (uint256[3][] memory)
    {
        uint256[3][] memory amountPools = new uint256[3][](_pids.length);

        for (uint8 i = 0; i < _pids.length; i++) {
            uint256 userOfferingAmountPool;
            uint256 userRefundingAmountPool;
            uint256 userTaxAmountPool;

            if (poolInfo[_pids[i]].raisingAmount > 0) {
                (
                    userOfferingAmountPool,
                    userRefundingAmountPool,
                    userTaxAmountPool
                ) = _calcOfferingAndRefundingAmounts(_user, _pids[i]);
            }

            amountPools[i] = [userOfferingAmountPool / HARVEST_PERIODS, userRefundingAmountPool, userTaxAmountPool];
        }
        return amountPools;
    }
}
