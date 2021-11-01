// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../farm/SolarVault.sol";
import "./ICommonEclipse.sol";

contract CommonEclipse is ICommonEclipse, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    IERC20 public lpToken;
    IERC20 public offeringToken;

    SolarVault public vault;

    uint8 public constant HARVEST_PERIODS = 4; // number of periods to split offering token to vest.

    uint8 public constant NUMBER_VAULT_POOLS = 3; // number of solar vault pools to check for stake.

    uint8 public constant NUMBER_THRESHOLDS = 3; // number of solar staked threshold for multipliers per pool.

    uint256[HARVEST_PERIODS] public harvestReleaseBlocks;
    uint256[HARVEST_PERIODS] public harvestReleasePercent;

    uint256 public startBlock;

    uint256 public endBlock;

    uint256 public eligibilityThreshold; // minimum solar staked to be eligible.

    bool public claimEnabled = false; // flag to enable harvests after liquidity is added.

    /**
     * @dev The struct stores the each pools base multiplier, and additional
     * multipliers based on meeting staked threshold requirements.
     */
    struct Multipliers {
        uint16[NUMBER_THRESHOLDS] poolThresholds;
        uint8[NUMBER_VAULT_POOLS] poolBaseMult;
        uint8[NUMBER_THRESHOLDS][NUMBER_VAULT_POOLS] poolMultipliers;
    }

    struct UserInfo {
        uint256 amount; // How many tokens the user has provided for pool
        uint256 allocPoints; // Used to weight user allocation based on amount locked in solar vaults
        bool[HARVEST_PERIODS] claimed; // Whether the user has claimed (default: false) for pool
        bool isRefunded; // Wheter the user has been refunded or not.
    }

    struct PoolInfo {
        uint256 raisingAmount; // amount of tokens raised for the pool (in LP tokens)
        uint256 offeringAmount; // amount of tokens offered for the pool (in offeringTokens)
        uint256 baseLimitInLP; // base limit of tokens per eligible user (if 0, it is ignored)
        bool hasTax; // if a pool is to be taxed on overflow or not
        uint256 totalAmountPool; // total amount pool deposited (in LP tokens)
        uint256 sumTaxesOverflow; // total taxes collected (starts at 0, increases with each harvest if overflow)
        uint256 totalAllocPoints;
    }

    uint8 public constant numberPools = 2; // max number of pools that are to be created.

    mapping(address => mapping(uint8 => UserInfo)) public userInfo;

    PoolInfo[numberPools] public poolInfo;

    Multipliers private _multiplierInfo;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed user, uint256 amount, uint256 indexed pid);
    event Withdraw(address indexed user, uint256 amount, uint256 indexed pid);
    event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event PoolParametersSet(uint256 raisingAmount, uint256 offeringAmount, uint8 pid);
    event MultiplierParametersSet(
        uint16[NUMBER_THRESHOLDS] poolStakedThresholds,
        uint8[NUMBER_VAULT_POOLS] poolBaseMultiplier,
        uint8[NUMBER_THRESHOLDS][NUMBER_VAULT_POOLS] poolStakedMultipliers
        );
    event AdminWithdraw(uint256 amountLP, uint256 amountOfferingToken);
    event AdminTokenRecovery(address token, uint256 amount);
    event ClaimEnabled();

    /*///////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice It checks if the current block is within the sale period.
     */
    modifier onlyWhenActive() {
        require(
            block.number >= startBlock && block.number < endBlock,
            "Sale not active"
        );
        _;
    }
    /**
     * @notice It checks if sale ended and claim is enabled
     */
    modifier onlyFinished() {
        require(block.number >= endBlock && claimEnabled, "sale not finished");
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
        uint256 _eligibilityThreshold, // (1e18)
        address _solarVault,
        uint256[] memory _harvestReleasePercent,
        bytes memory _multipliers
    ){
        require(_lpToken.totalSupply() >= 0);
        require(_offeringToken.totalSupply() >= 0);
        require(_lpToken != _offeringToken, "Tokens must be different");
        require(_harvestReleasePercent.length == HARVEST_PERIODS, "harvest schedule must match");

        uint256 totalPercent = 0;
        for (uint256 i = 0; i < _harvestReleasePercent.length; i++) {
            totalPercent += _harvestReleasePercent[i];
        }

        require(totalPercent == 10000, "harvest percent must total 10000");

        lpToken = _lpToken;
        offeringToken = _offeringToken;
        startBlock = _startBlock;
        endBlock = _endBlock;
        eligibilityThreshold = _eligibilityThreshold;
        vault = SolarVault(_solarVault);

        _setMultipliers(_multipliers);

        for (uint256 i = 0; i < HARVEST_PERIODS; i++) {
            harvestReleaseBlocks[i] = endBlock + (_vestingBlockOffset * i);
            harvestReleasePercent[i] = _harvestReleasePercent[i];
        }
    }

    function setOfferingToken(IERC20 _offeringToken) public onlyOwner {
        require(block.number < startBlock, "sale is already active");        
        require(_offeringToken.totalSupply() >= 0);
        offeringToken = _offeringToken;
    }

    /*///////////////////////////////////////////////////////////////
                            POOL MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice It sets the threshold of solar staked to be eligible to participate.
     * @param _eligibilityThreshold: Number of solar staked to be eligibile. (1e18)
     */
    function setEligibilityThreshold(uint256 _eligibilityThreshold) public override onlyOwner {
        require(block.number < startBlock, "sale is already active");
        eligibilityThreshold = _eligibilityThreshold;
    }
    /**
     * @notice It sets the multiplier matrix.
     * @param _multipliers: abi encoded arrays
     */
    function setMultipliers(bytes memory _multipliers) public override onlyOwner {
        require(block.number < startBlock, "sale is already active");
        _setMultipliers(_multipliers);
    }
    /**
     * @notice Private helper to set multiplier matrix.
     */
    function _setMultipliers(bytes memory _multipliers) private {
        (
            uint16[] memory thresholds,
            uint8[] memory base,
            uint8[][] memory mults

            ) = abi.decode(_multipliers,(
                uint16[],
                uint8[],
                uint8[][]
            ));
        require(
            base.length == NUMBER_VAULT_POOLS && mults.length == NUMBER_VAULT_POOLS,
            "bad vault pool length"
        );
        require(thresholds.length == NUMBER_THRESHOLDS ,"bad threshold length");

        for (uint8 i = 0; i < NUMBER_THRESHOLDS; i++) {
            _multiplierInfo.poolThresholds[i] =  thresholds[i];
        }

        for (uint8 i = 0; i < NUMBER_VAULT_POOLS; i++){
            _multiplierInfo.poolBaseMult[i] = base[i];
            require(mults[i].length == NUMBER_THRESHOLDS, "bad threshold length");
            for ( uint8 j = 0; j < NUMBER_THRESHOLDS; j++) {
               _multiplierInfo.poolMultipliers[i][j] =  mults[i][j];
            }
        }

        emit MultiplierParametersSet(
            _multiplierInfo.poolThresholds,
            _multiplierInfo.poolBaseMult,
            _multiplierInfo.poolMultipliers
        );
    }

    /**
     * @notice It creates a pool.
     * @dev If _baseLimitInLP is set to zero, the allocation will be weighted by allocation points. (see below)
     * @param _raisingAmount: amount of LP token the pool aims to raise (1e18)
     * @param _offeringAmount: amount of IDO tokens the pool is offering (1e18)
     * @param _baseLimitInLP: base limit of tokens per eligible user (if 0, it is ignored) (1e18)
     * @param _hasTax: true if a pool is to be taxed on overflow
     * @param _pid: pool identification number
     */
    function setPool(
        uint256 _raisingAmount,
        uint256 _offeringAmount,
        uint256 _baseLimitInLP,
        bool _hasTax,
        uint8 _pid
    ) external override onlyOwner{
        require(block.number < startBlock, "sale is already active");
        require(_pid < numberPools, "pool does not exist");

        poolInfo[_pid].raisingAmount = _raisingAmount;
        poolInfo[_pid].offeringAmount = _offeringAmount;
        poolInfo[_pid].baseLimitInLP = _baseLimitInLP;
        poolInfo[_pid].hasTax = _hasTax;

        emit PoolParametersSet(_offeringAmount, _raisingAmount, _pid);
    }
    /**
     * @notice It sets the start and end blocks of the sale.
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock) external override onlyOwner {
        require(block.number < startBlock, "sale is already active");
        require(_startBlock < _endBlock, "new startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        endBlock = _endBlock;

        emit NewStartAndEndBlocks(_startBlock, _endBlock);
    }
    /**
     * @notice It allows the owner to withdraw LPtokens and Offering tokens after the sale
     * @dev can only withdraw after the sale is finished
     * @param _lpAmount: amount of LP token to withdraw
     * @param _offerAmount: amount of IDO tokens to withdraw
     */
    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) external override onlyOwner {
        require(block.number > endBlock, "sale has not finished");
        require(_lpAmount <= lpToken.balanceOf(address(this)), "Not enough LP tokens");
        require(_offerAmount <= offeringToken.balanceOf(address(this)), "Not enough offering tokens");

        if (_lpAmount > 0) {
            lpToken.safeTransfer(address(msg.sender), _lpAmount);
        }

        if (_offerAmount > 0) {
            offeringToken.safeTransfer(address(msg.sender), _offerAmount);
        }

        emit AdminWithdraw(_lpAmount, _offerAmount);
    }
    /**
     * @notice It allows the owner to withdraw ERC20 tokens
     * @dev cannot withdraw LP tokens or Offering tokens
     * @param _tokenAddress: address of ERC20 token to withdraw
     * @param _amount: amount to withdraw
     */
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
    /**
     * @notice It lets users deposit into a pool for a share of offering tokens
     * @dev cannot withdraw LP tokens or Offering tokens
     * @param _amount: amount of LP tokens to deposit
     * @param _pid: pool to depoist in
     */
    function depositPool(uint256 _amount, uint8 _pid) external override onlyWhenActive nonReentrant {
        UserInfo storage user = userInfo[msg.sender][_pid];

        require(_pid < numberPools, "pool does not exist");

        require(
            poolInfo[_pid].offeringAmount > 0 && poolInfo[_pid].raisingAmount > 0,
            "Pool not set"
        );

        for (uint8 i = 0; i < numberPools; i++) {
          if (i != _pid) {
            require(userInfo[msg.sender][i].amount == 0, "already commited in another pool");
          }
        }

        for (uint256 i=0; i<NUMBER_VAULT_POOLS; i++) {
            vault.deposit(i,0);
        }
        (bool success) = getUserEligibility(address(msg.sender));
        require(success, "user not eligible");

        lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);

        user.amount += _amount;

        if (poolInfo[_pid].baseLimitInLP > 0) {
            (uint16 multiplier) = getUserMultiplier(msg.sender);
            require(
                user.amount <= (poolInfo[_pid].baseLimitInLP * uint256(multiplier)), "New amount above user limit"
            );
        } else {
            (uint16 multiplier) = getUserMultiplier(msg.sender);
            poolInfo[_pid].totalAllocPoints -= userInfo[msg.sender][_pid].allocPoints;
            userInfo[msg.sender][_pid].allocPoints = user.amount * uint256(multiplier);
            poolInfo[_pid].totalAllocPoints += userInfo[msg.sender][_pid].allocPoints;
        }
        poolInfo[_pid].totalAmountPool += _amount;

        emit Deposit(msg.sender,_amount,_pid);

    }


    function getUserEligibility(address _user) public view returns(bool) {
        uint256 amount;

        for (uint256 i=0; i<NUMBER_VAULT_POOLS; i++) {
            (amount,,,,) = vault.userInfo(i,_user);
            if(amount >= eligibilityThreshold) {
                return true;
            }
        }
        return false;
    }
    
    function getUserMultiplier(address _user) public view returns(uint16) {
        uint16 userMult;
        uint16 mult;
        uint256 amount;
        for (uint8 i=0; i<NUMBER_VAULT_POOLS; i++) {
            (amount,,,,) = vault.userInfo(i,_user);
            for (uint8 j=0; j<NUMBER_THRESHOLDS; j++) {
                mult = uint16(_multiplierInfo.poolBaseMult[i]) * uint16(_multiplierInfo.poolMultipliers[i][j]);
                if(amount >= uint256(_multiplierInfo.poolThresholds[j])*1e18) {
                    if(mult > userMult) {
                        userMult = mult;
                    }
                }
            }
        }
        return (userMult);
    }

    /*///////////////////////////////////////////////////////////////
                            WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/
    function withdrawPool(uint256 _amount, uint8 _pid)
        external
        override
        nonReentrant
        onlyWhenActive
    {
        UserInfo storage user = userInfo[msg.sender][_pid];
        require(_pid < numberPools, "pool does not exist");
        require(
            poolInfo[_pid].offeringAmount > 0 &&
                poolInfo[_pid].raisingAmount > 0,
            "pool not set"
        );

        require(
            _amount > 0 && user.amount > 0 && user.amount >= _amount,
            "withdraw: amount higher than user balance"
        );

        user.amount -= _amount;
        poolInfo[_pid].totalAmountPool -= _amount;

        if (poolInfo[_pid].baseLimitInLP == 0) {
            (uint16 multiplier) = getUserMultiplier(msg.sender);
            poolInfo[_pid].totalAllocPoints -= userInfo[msg.sender][_pid].allocPoints;
            userInfo[msg.sender][_pid].allocPoints = user.amount * uint256(multiplier);
            poolInfo[_pid].totalAllocPoints += userInfo[msg.sender][_pid].allocPoints;
        }

        lpToken.safeTransfer(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _amount, _pid);
    }

    /*///////////////////////////////////////////////////////////////
                            HARVEST LOGIC
    //////////////////////////////////////////////////////////////*/
    function harvestPool(uint8 _pid, uint8 _harvestPeriod) external override nonReentrant onlyFinished {
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
        if (userTaxOverflow > 0 && !userInfo[msg.sender][_pid].isRefunded) {
            poolInfo[_pid].sumTaxesOverflow += userTaxOverflow;
        }
        if (refundingTokenAmount > 0 && !userInfo[msg.sender][_pid].isRefunded) {
            userInfo[msg.sender][_pid].isRefunded = true;
            lpToken.safeTransfer(address(msg.sender), refundingTokenAmount);
        }

        uint256 offeringTokenAmountPerPeriod;
        if (offeringTokenAmount > 0) {
            offeringTokenAmountPerPeriod = offeringTokenAmount * harvestReleasePercent[_harvestPeriod] / 1e4;
            offeringToken.safeTransfer(address(msg.sender), offeringTokenAmountPerPeriod);
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

            uint256 payAmount = poolInfo[_pid].raisingAmount * userInfo[_user][_pid].amount * 1e18 / poolInfo[_pid].totalAmountPool  / 1e18;

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
            } else {
                userOfferingAmount = poolInfo[_pid].offeringAmount * _getUserAllocation(_user,_pid) / 1e12;
            }
        }
        return (userOfferingAmount, userRefundingAmount, taxAmount);
    }
    /**
     * @notice It returns the user allocation for pool
     * @dev (1e8) 10,000,000 means 0.1 (10%) / 1 means 0.000000001 (0.0000001%) / 100,000,000 means 1 (100%)
     * @param _user: user address
     * @param _pid: pool id
     * @return it returns the user's share of pool
     */
    function _getUserAllocation(address _user, uint8 _pid) view internal  returns (uint256) {
        if (poolInfo[_pid].totalAmountPool > 0) {
            if(poolInfo[_pid].baseLimitInLP > 0) {
                return userInfo[_user][_pid].amount * 1e18 / poolInfo[_pid].totalAmountPool / 1e6;
            } else {
                return userInfo[_user][_pid].allocPoints * 1e18 / poolInfo[_pid].totalAllocPoints / 1e6;
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

            amountPools[i] = [userOfferingAmountPool, userRefundingAmountPool, userTaxAmountPool];
        }
        return amountPools;
    }

    function viewMultipliers()
        public
        view
        returns(
            uint16[] memory,
            uint8[] memory,
            uint8[][] memory
        )
    {
        uint16[] memory _poolThresholds = new uint16[](_multiplierInfo.poolThresholds.length);
        for (uint16 i = 0; i < _multiplierInfo.poolThresholds.length ;i++) {
            _poolThresholds[i] = _multiplierInfo.poolThresholds[i];
        }

        uint8[] memory _poolBaseMult = new uint8[](_multiplierInfo.poolBaseMult.length);
        for (uint8 i = 0; i < _multiplierInfo.poolBaseMult.length ;i++) {
            _poolBaseMult[i] = _multiplierInfo.poolBaseMult[i];
        }

        uint8[][] memory _poolMultipliers = new uint8[][](_multiplierInfo.poolMultipliers.length);
        for (uint8 i = 0; i < _multiplierInfo.poolMultipliers.length;i++) {
            _poolMultipliers[i] = new uint8[](_multiplierInfo.poolMultipliers[i].length);
            for (uint8 j = 0;j < _multiplierInfo.poolMultipliers[i].length;j++) {
                _poolMultipliers[i][j] = _multiplierInfo.poolMultipliers[i][j];
            }
        }

        return(
            _poolThresholds,
            _poolBaseMult,
            _poolMultipliers
        );
    }

    function enableClaim() external override onlyOwner {
        require(block.number >= endBlock, "sale still active");
        require(!claimEnabled, "claim is already enabled");

        claimEnabled = true;

        emit ClaimEnabled();
    }

}
