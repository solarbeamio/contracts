// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./rewarders/IRewarder.sol";
import "./libraries/BoringERC20.sol";

contract SolarDistributorV2 is Ownable, ReentrancyGuard {
    using BoringERC20 for IBoringERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
    }

    // Info of each pool.
    struct PoolInfo {
        IBoringERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Solar to distribute per block.
        uint256 lastRewardBlock; // Last block number that Solar distribution occurs.
        uint256 accSolarPerShare; // Accumulated Solar per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 harvestInterval; // Harvest interval in seconds
        uint256 totalLp; // Total token in Pool
        IRewarder[] rewarders; // Array of rewarder contract for pools with incentives
    }

    IBoringERC20 public solar;

    // Solar tokens created per block
    uint256 public solarPerBlock;

    // Max harvest interval: 14 days
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // Maximum deposit fee rate: 10%
    uint16 public constant MAXIMUM_DEPOSIT_FEE_RATE = 1000;

    // Info of each pool
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when Solar mining starts.
    uint256 public startBlock;

    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Total Solar in Solar Pools (can be multiple pools)
    uint256 public totalSolarInPools = 0;

    // Team address.
    address public teamAddress;

    // Treasury address.
    address public treasuryAddress;

    // Investor address.
    address public investorAddress;

    // Percentage of pool rewards that goto the team.
    uint256 public teamPercent;

    // Percentage of pool rewards that goes to the treasury.
    uint256 public treasuryPercent;

    // Percentage of pool rewards that goes to the investor.
    uint256 public investorPercent;

    modifier validatePoolByPid(uint256 _pid) {
        require(_pid < poolInfo.length, "Pool does not exist");
        _;
    }

    event Add(
        uint256 indexed pid,
        uint256 allocPoint,
        IBoringERC20 indexed lpToken,
        uint16 depositFeeBP,
        uint256 harvestInterval,
        IRewarder[] indexed rewarders
    );

    event Set(
        uint256 indexed pid,
        uint256 allocPoint,
        uint16 depositFeeBP,
        uint256 harvestInterval,
        IRewarder[] indexed rewarders
    );

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event EmissionRateUpdated(
        address indexed caller,
        uint256 previousAmount,
        uint256 newAmount
    );

    event RewardLockedUp(
        address indexed user,
        uint256 indexed pid,
        uint256 amountLockedUp
    );

    event AllocPointsUpdated(
        address indexed caller,
        uint256 previousAmount,
        uint256 newAmount
    );

    event SetTeamAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    event SetTreasuryAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    event SetInvestorAddress(
        address indexed oldAddress,
        address indexed newAddress
    );

    event SetTeamPercent(uint256 oldPercent, uint256 newPercent);

    event SetTreasuryPercent(uint256 oldPercent, uint256 newPercent);

    event SetInvestorPercent(uint256 oldPercent, uint256 newPercent);

    constructor(
        IBoringERC20 _solar,
        uint256 _solarPerBlock,
        address _teamAddress,
        address _treasuryAddress,
        address _investorAddress,
        uint256 _teamPercent,
        uint256 _treasuryPercent,
        uint256 _investorPercent
    ) {
        require(
            0 <= _teamPercent && _teamPercent <= 1000,
            "constructor: invalid team percent value"
        );
        require(
            0 <= _treasuryPercent && _treasuryPercent <= 1000,
            "constructor: invalid treasury percent value"
        );
        require(
            0 <= _investorPercent && _investorPercent <= 1000,
            "constructor: invalid investor percent value"
        );
        require(
            _teamPercent + _treasuryPercent + _investorPercent <= 1000,
            "constructor: total percent over max"
        );

        //StartBlock always many years later from contract construct, will be set later in StartFarming function
        startBlock = block.number + (10 * 365 * 24 * 60 * 60);

        solar = _solar;
        solarPerBlock = _solarPerBlock;

        teamAddress = _teamAddress;
        treasuryAddress = _treasuryAddress;
        investorAddress = _investorAddress;

        teamPercent = _teamPercent;
        treasuryPercent = _treasuryPercent;
        investorPercent = _investorPercent;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to - _from;
    }

    // Set farming start, can call only once
    function startFarming() public onlyOwner {
        require(
            block.number < startBlock,
            "startFarming: farm started already"
        );

        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = block.number;
        }

        startBlock = block.number;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // Can add multiple pool with same lp token without messing up rewards, because each pool's balance is tracked using its own totalLp
    function add(
        uint256 _allocPoint,
        IBoringERC20 _lpToken,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        IRewarder[] calldata _rewarders
    ) public onlyOwner {
        require(
            _depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE,
            "add: deposit fee too high"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "add: invalid harvest interval"
        );
        require(
            Address.isContract(address(_lpToken)),
            "add: LP token must be a valid contract"
        );

        for (
            uint256 rewarderId = 0;
            rewarderId < _rewarders.length;
            ++rewarderId
        ) {
            require(
                Address.isContract(address(_rewarders[rewarderId])),
                "add: rewarder must be contract"
            );
        }

        massUpdatePools();

        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;

        totalAllocPoint = totalAllocPoint + _allocPoint;

        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSolarPerShare: 0,
                depositFeeBP: _depositFeeBP,
                harvestInterval: _harvestInterval,
                totalLp: 0,
                rewarders: _rewarders
            })
        );

        emit Add(
            poolInfo.length - 1,
            _allocPoint,
            _lpToken,
            _depositFeeBP,
            _harvestInterval,
            _rewarders
        );
    }

    // Update the given pool's Solar allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        IRewarder[] calldata _rewarders
    ) public onlyOwner validatePoolByPid(_pid) {
        require(
            _depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE,
            "set: deposit fee too high"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "set: invalid harvest interval"
        );

        for (
            uint256 rewarderId = 0;
            rewarderId < _rewarders.length;
            ++rewarderId
        ) {
            require(
                Address.isContract(address(_rewarders[rewarderId])),
                "add: rewarder must be contract"
            );
        }

        massUpdatePools();

        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;

        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].rewarders = _rewarders;

        emit Set(
            _pid,
            _allocPoint,
            _depositFeeBP,
            _harvestInterval,
            _rewarders
        );
    }

    // View function to see pending rewards on frontend.
    function pendingTokens(uint256 _pid, address _user)
        external
        view
        validatePoolByPid(_pid)
        returns (
            address[] memory addresses,
            string[] memory symbols,
            uint256[] memory amounts
        )
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSolarPerShare = pool.accSolarPerShare;
        uint256 lpSupply = pool.totalLp;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );

            uint256 solarReward = ((multiplier * solarPerBlock) *
                pool.allocPoint) / totalAllocPoint;

            accSolarPerShare =
                accSolarPerShare +
                (((solarReward * 1e12) / lpSupply));
        }

        uint256 pendingSolar = (((user.amount * accSolarPerShare) / 1e12) -
            user.rewardDebt) + user.rewardLockedUp;

        addresses = new address[](pool.rewarders.length + 1);
        symbols = new string[](pool.rewarders.length + 1);
        amounts = new uint256[](pool.rewarders.length + 1);

        addresses[0] = address(solar);
        symbols[0] = IBoringERC20(solar).safeSymbol();
        amounts[0] = pendingSolar;

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            addresses[rewarderId + 1] = address(
                pool.rewarders[rewarderId].rewardToken()
            );

            symbols[rewarderId + 1] = IBoringERC20(
                pool.rewarders[rewarderId].rewardToken()
            ).safeSymbol();

            amounts[rewarderId + 1] = pool.rewarders[rewarderId].pendingTokens(
                _user
            );
        }
    }

    // View function to see rewarders for a pool
    function poolRewarders(uint256 _pid)
        external
        view
        validatePoolByPid(_pid)
        returns (address[] memory rewarders)
    {
        PoolInfo storage pool = poolInfo[_pid];

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            rewarders[rewarderId] = address(pool.rewarders[rewarderId]);
        }
    }

    // View function to see if user can harvest Solar.
    function canHarvest(uint256 _pid, address _user)
        public
        view
        validatePoolByPid(_pid)
        returns (bool)
    {
        UserInfo storage user = userInfo[_pid][_user];
        return
            block.number >= startBlock &&
            block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 lpSupply = pool.totalLp;

        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);

        uint256 solarReward = ((multiplier * solarPerBlock) * pool.allocPoint) /
            totalAllocPoint;

        uint256 lpPercent = 1000 -
            teamPercent -
            treasuryPercent -
            investorPercent;

        solar.mint(teamAddress, (solarReward * teamPercent) / 1000);
        solar.mint(treasuryAddress, (solarReward * treasuryPercent) / 1000);
        solar.mint(investorAddress, (solarReward * investorPercent) / 1000);
        solar.mint(address(this), (solarReward * lpPercent) / 1000);

        pool.accSolarPerShare =
            pool.accSolarPerShare +
            (((solarReward * 1e12) / pool.totalLp) * lpPercent) /
            1000;
        pool.lastRewardBlock = block.number;
    }

    // Deposit tokens for Solar allocation.
    function deposit(uint256 _pid, uint256 _amount)
        public
        nonReentrant
        validatePoolByPid(_pid)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        updatePool(_pid);

        payOrLockupPendingSolar(_pid);

        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));

            _amount = afterDeposit - beforeDeposit;

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = (_amount * pool.depositFeeBP) / 10000;
                pool.lpToken.safeTransfer(treasuryAddress, depositFee);

                _amount = _amount - depositFee;
            }

            user.amount = user.amount + _amount;
            pool.totalLp = pool.totalLp + _amount;

            if (address(pool.lpToken) == address(solar)) {
                totalSolarInPools = totalSolarInPools + _amount;
            }
        }
        user.rewardDebt = (user.amount * pool.accSolarPerShare) / 1e12;

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            pool.rewarders[rewarderId].onSolarReward(msg.sender, user.amount);
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens
    function withdraw(uint256 _pid, uint256 _amount)
        public
        nonReentrant
        validatePoolByPid(_pid)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        //this will make sure that user can only withdraw from his pool
        require(user.amount >= _amount, "withdraw: user amount not enough");

        //Cannot withdraw more than pool's balance
        require(pool.totalLp >= _amount, "withdraw: pool total not enough");

        updatePool(_pid);

        payOrLockupPendingSolar(_pid);

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.totalLp = pool.totalLp - _amount;
            if (address(pool.lpToken) == address(solar)) {
                totalSolarInPools = totalSolarInPools - _amount;
            }
            pool.lpToken.safeTransfer(msg.sender, _amount);
        }
        user.rewardDebt = (user.amount * pool.accSolarPerShare) / 1e12;

        for (
            uint256 rewarderId = 0;
            rewarderId < pool.rewarders.length;
            ++rewarderId
        ) {
            pool.rewarders[rewarderId].onSolarReward(msg.sender, user.amount);
        }

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;

        //Cannot withdraw more than pool's balance
        require(
            pool.totalLp >= amount,
            "emergency withdraw: pool total not enough"
        );

        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.totalLp = pool.totalLp - amount;

        if (address(pool.lpToken) == address(solar)) {
            totalSolarInPools = totalSolarInPools - amount;
        }

        pool.lpToken.safeTransfer(msg.sender, amount);

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending Solar.
    function payOrLockupPendingSolar(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0 && block.number >= startBlock) {
            user.nextHarvestUntil = block.timestamp + pool.harvestInterval;
        }

        uint256 pending = ((user.amount * pool.accSolarPerShare) / 1e12) -
            user.rewardDebt;

        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending + user.rewardLockedUp;

                // reset lockup
                totalLockedUpRewards =
                    totalLockedUpRewards -
                    user.rewardLockedUp;

                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp + pool.harvestInterval;

                // send rewards
                safeSolarTransfer(msg.sender, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp + pending;
            totalLockedUpRewards = totalLockedUpRewards + pending;
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe Solar transfer function, just in case if rounding error causes pool do not have enough Solar.
    function safeSolarTransfer(address _to, uint256 _amount) internal {
        if (solar.balanceOf(address(this)) > totalSolarInPools) {
            //solarBal = total Solar in SolarDistributor - total Solar in Solar pools, this will make sure that SolarDistributor never transfer rewards from deposited Solar pools
            uint256 solarBal = solar.balanceOf(address(this)) -
                totalSolarInPools;
            if (_amount >= solarBal) {
                solar.safeTransfer(_to, solarBal);
            } else if (_amount > 0) {
                solar.safeTransfer(_to, _amount);
            }
        }
    }

    function updateEmissionRate(uint256 _solarPerBlock) public onlyOwner {
        massUpdatePools();

        emit EmissionRateUpdated(msg.sender, solarPerBlock, _solarPerBlock);

        solarPerBlock = _solarPerBlock;
    }

    function updateAllocPoint(uint256 _pid, uint256 _allocPoint)
        public
        onlyOwner
    {
        massUpdatePools();

        emit AllocPointsUpdated(
            msg.sender,
            poolInfo[_pid].allocPoint,
            _allocPoint
        );

        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Function to harvest many pools in a single transaction
    function harvestMany(uint256[] calldata _pids) public {
        for (uint256 index = 0; index < _pids.length; ++index) {
            deposit(_pids[index], 0);
        }
    }

    // Update team address by the previous team address.
    function setTeamAddress(address _teamAddress) public {
        require(
            msg.sender == teamAddress,
            "set team address: only previous team address can call this method"
        );
        teamAddress = _teamAddress;
        emit SetTeamAddress(msg.sender, _teamAddress);
    }

    function setTeamPercent(uint256 _newTeamPercent) public onlyOwner {
        require(
            0 <= _newTeamPercent && _newTeamPercent <= 1000,
            "set team percent: invalid percent value"
        );
        require(
            treasuryPercent + _newTeamPercent + investorPercent <= 1000,
            "set team percent: total percent over max"
        );
        emit SetTeamPercent(teamPercent, _newTeamPercent);
        teamPercent = _newTeamPercent;
    }

    // Update treasury address by the previous treasury.
    function setTreasuryAddr(address _treasuryAddress) public {
        require(msg.sender == treasuryAddress, "set treasury address: wut?");
        treasuryAddress = _treasuryAddress;
        emit SetTreasuryAddress(msg.sender, _treasuryAddress);
    }

    function setTreasuryPercent(uint256 _newTreasuryPercent) public onlyOwner {
        require(
            0 <= _newTreasuryPercent && _newTreasuryPercent <= 1000,
            "set treasury percent: invalid percent value"
        );
        require(
            teamPercent + _newTreasuryPercent + investorPercent <= 1000,
            "set treasury percent: total percent over max"
        );
        emit SetTeamPercent(treasuryPercent, _newTreasuryPercent);
        treasuryPercent = _newTreasuryPercent;
    }

    // Update the investor address by the previous investor.
    function setInvestorAddress(address _investorAddress) public {
        require(
            msg.sender == investorAddress,
            "set investor address: only previous investor can call this method"
        );
        investorAddress = _investorAddress;
        emit SetInvestorAddress(msg.sender, _investorAddress);
    }

    function setInvestorPercent(uint256 _newInvestorPercent) public onlyOwner {
        require(
            0 <= _newInvestorPercent && _newInvestorPercent <= 1000,
            "set investor percent: invalid percent value"
        );
        require(
            teamPercent + _newInvestorPercent + treasuryPercent <= 1000,
            "set investor percent: total percent over max"
        );
        emit SetTeamPercent(investorPercent, _newInvestorPercent);
        investorPercent = _newInvestorPercent;
    }
}
