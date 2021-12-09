// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.4.0

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IBoringERC20 {
    function mint(address to, uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File contracts/libraries/BoringERC20.sol

// solhint-disable avoid-low-level-calls
library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IBoringERC20 token)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_SYMBOL)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IBoringERC20 token)
        internal
        view
        returns (string memory)
    {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_NAME)
        );
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IBoringERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(SIG_DECIMALS)
        );
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IBoringERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: Transfer failed"
        );
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IBoringERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "BoringERC20: TransferFrom failed"
        );
    }
}


// File contracts/staking/TokenFarm.sol

contract TokenFarm is Ownable, ReentrancyGuard {
    using BoringERC20 for IBoringERC20;

    // Info of each user for each farm.
    struct UserInfo {
        uint256 amount; // How many Staking tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each reward distribution campaign.
    struct CampaignInfo {
        IBoringERC20 stakingToken; // Address of Staking token contract.
        IBoringERC20 rewardToken; // Address of Reward token contract
        uint256 precision; //reward token precision
        uint256 startTimestamp; // start timestamp of the campaign
        uint256 lastRewardTimestamp; // Last timestamp that Reward Token distribution occurs.
        uint256 accRewardPerShare; // Accumulated Reward Token per share. See below.
        uint256 totalStaked; // total staked amount each campaign's stake token, typically, each campaign has the same stake token, so need to track it separatedly
        uint256 totalRewards;
    }

    // Reward info
    struct RewardInfo {
        uint256 endTimestamp;
        uint256 rewardPerSec;
    }

    // @dev this is mostly used for extending reward period
    // @notice Reward info is a set of {endTimestamp, rewardPerTimestamp}
    // indexed by campaigh ID
    mapping(uint256 => RewardInfo[]) public campaignRewardInfo;

    // @notice Info of each campaign. mapped from campaigh ID
    CampaignInfo[] public campaignInfo;
    // Info of each user that stakes Staking tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // @notice limit length of reward info
    // how many phases are allowed
    uint256 public rewardInfoLimit;
    // @dev reward holder account
    address public rewardHolder;

    event Deposit(address indexed user, uint256 amount, uint256 campaign);
    event Withdraw(address indexed user, uint256 amount, uint256 campaign);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount,
        uint256 campaign
    );
    event AddCampaignInfo(
        uint256 indexed campaignID,
        IBoringERC20 stakingToken,
        IBoringERC20 rewardToken,
        uint256 startTimestamp
    );
    event AddRewardInfo(
        uint256 indexed campaignID,
        uint256 indexed phase,
        uint256 endTimestamp,
        uint256 rewardPerTimestamp
    );
    event SetRewardInfoLimit(uint256 rewardInfoLimit);
    event SetRewardHolder(address rewardHolder);

    // constructor
    constructor(address _rewardHolder) {
        rewardInfoLimit = 53;
        rewardHolder = _rewardHolder;
    }

    // @notice function for setting a reward holder who is responsible for adding a reward info
    function setRewardHolder(address _rewardHolder) external onlyOwner {
        rewardHolder = _rewardHolder;
        emit SetRewardHolder(_rewardHolder);
    }

    // @notice set new reward info limit
    function setRewardInfoLimit(uint256 _updatedRewardInfoLimit)
        external
        onlyOwner
    {
        rewardInfoLimit = _updatedRewardInfoLimit;
        emit SetRewardInfoLimit(rewardInfoLimit);
    }

    // @notice reward campaign, one campaign represents a pair of staking and reward token, last reward Timestamp and acc reward Per Share
    function addCampaignInfo(
        IBoringERC20 _stakingToken,
        IBoringERC20 _rewardToken,
        uint256 _startTimestamp
    ) external onlyOwner {
        uint256 decimalsRewardToken = uint256(_rewardToken.safeDecimals());

        require(
            decimalsRewardToken < 30,
            "constructor: reward token decimals must be inferior to 30"
        );

        uint256 precision = uint256(10**(uint256(30) - (decimalsRewardToken)));

        campaignInfo.push(
            CampaignInfo({
                stakingToken: _stakingToken,
                rewardToken: _rewardToken,
                precision: precision,
                startTimestamp: _startTimestamp,
                lastRewardTimestamp: _startTimestamp,
                accRewardPerShare: 0,
                totalStaked: 0,
                totalRewards: 0
            })
        );
        emit AddCampaignInfo(
            campaignInfo.length - 1,
            _stakingToken,
            _rewardToken,
            _startTimestamp
        );
    }

    // @notice if the new reward info is added, the reward & its end timestamp will be extended by the newly pushed reward info.
    function addRewardInfo(
        uint256 _campaignID,
        uint256 _endTimestamp,
        uint256 _rewardPerSec
    ) external onlyOwner {
        RewardInfo[] storage rewardInfo = campaignRewardInfo[_campaignID];
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        require(
            rewardInfo.length < rewardInfoLimit,
            "addRewardInfo::reward info length exceeds the limit"
        );
        require(
            rewardInfo.length == 0 ||
                rewardInfo[rewardInfo.length - 1].endTimestamp >=
                block.timestamp,
            "addRewardInfo::reward period ended"
        );
        require(
            rewardInfo.length == 0 ||
                rewardInfo[rewardInfo.length - 1].endTimestamp < _endTimestamp,
            "addRewardInfo::bad new endTimestamp"
        );
        uint256 startTimestamp = rewardInfo.length == 0
            ? campaign.startTimestamp
            : rewardInfo[rewardInfo.length - 1].endTimestamp;
        uint256 timeRange = _endTimestamp - startTimestamp;
        uint256 totalRewards = _rewardPerSec * timeRange;
        campaign.rewardToken.safeTransferFrom(
            rewardHolder,
            address(this),
            totalRewards
        );
        campaign.totalRewards += totalRewards;
        rewardInfo.push(
            RewardInfo({
                endTimestamp: _endTimestamp,
                rewardPerSec: _rewardPerSec
            })
        );
        emit AddRewardInfo(
            _campaignID,
            rewardInfo.length - 1,
            _endTimestamp,
            _rewardPerSec
        );
    }

    function rewardInfoLen(uint256 _campaignID)
        external
        view
        returns (uint256)
    {
        return campaignRewardInfo[_campaignID].length;
    }

    function campaignInfoLen() external view returns (uint256) {
        return campaignInfo.length;
    }

    // @notice this will return  end block based on the current block timestamp.
    function currentEndTimestamp(uint256 _campaignID)
        external
        view
        returns (uint256)
    {
        return _endTimestampOf(_campaignID, block.timestamp);
    }

    function _endTimestampOf(uint256 _campaignID, uint256 _blockTimestamp)
        internal
        view
        returns (uint256)
    {
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_blockTimestamp <= rewardInfo[i].endTimestamp)
                return rewardInfo[i].endTimestamp;
        }
        // @dev when couldn't find any reward info, it means that _blockTimestamp exceed endTimestamp
        // so return the latest reward info.
        return rewardInfo[len - 1].endTimestamp;
    }

    // @notice this will return reward per block based on the current block timestamp.
    function currentRewardPerSec(uint256 _campaignID)
        external
        view
        returns (uint256)
    {
        return _rewardPerSecOf(_campaignID, block.timestamp);
    }

    function _rewardPerSecOf(uint256 _campaignID, uint256 _blockTimestamp)
        internal
        view
        returns (uint256)
    {
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 len = rewardInfo.length;
        if (len == 0) {
            return 0;
        }
        for (uint256 i = 0; i < len; ++i) {
            if (_blockTimestamp <= rewardInfo[i].endTimestamp)
                return rewardInfo[i].rewardPerSec;
        }
        // @dev when couldn't find any reward info, it means that timestamp exceed endtimestamp
        // so return 0
        return 0;
    }

    // @notice Return reward multiplier over the given _from to _to timestamp.
    function getMultiplier(
        uint256 _from,
        uint256 _to,
        uint256 _endTimestamp
    ) public pure returns (uint256) {
        if ((_from >= _endTimestamp) || (_from > _to)) {
            return 0;
        }
        if (_to <= _endTimestamp) {
            return _to - _from;
        }
        return _endTimestamp - _from;
    }

    // @notice View function to see pending Reward on frontend.
    function pendingReward(uint256 _campaignID, address _user)
        external
        view
        returns (uint256)
    {
        return
            _pendingReward(
                _campaignID,
                userInfo[_campaignID][_user].amount,
                userInfo[_campaignID][_user].rewardDebt
            );
    }

    function _pendingReward(
        uint256 _campaignID,
        uint256 _amount,
        uint256 _rewardDebt
    ) internal view returns (uint256) {
        CampaignInfo memory campaign = campaignInfo[_campaignID];
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        uint256 accRewardPerShare = campaign.accRewardPerShare;
        if (
            block.timestamp > campaign.lastRewardTimestamp &&
            campaign.totalStaked != 0
        ) {
            uint256 cursor = campaign.lastRewardTimestamp;
            for (uint256 i = 0; i < rewardInfo.length; ++i) {
                uint256 multiplier = getMultiplier(
                    cursor,
                    block.timestamp,
                    rewardInfo[i].endTimestamp
                );
                if (multiplier == 0) continue;
                cursor = rewardInfo[i].endTimestamp;
                accRewardPerShare +=
                    ((multiplier * rewardInfo[i].rewardPerSec) *
                        campaign.precision) /
                    campaign.totalStaked;
            }
        }
        return
            ((_amount * accRewardPerShare) / campaign.precision) - _rewardDebt;
    }

    function updateCampaign(uint256 _campaignID) external nonReentrant {
        _updateCampaign(_campaignID);
    }

    // @notice Update reward variables of the given campaign to be up-to-date.
    function _updateCampaign(uint256 _campaignID) internal {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        RewardInfo[] memory rewardInfo = campaignRewardInfo[_campaignID];
        if (block.timestamp <= campaign.lastRewardTimestamp) {
            return;
        }
        if (campaign.totalStaked == 0) {
            // if there is no total supply, return and use the campaign's start block timestamp as the last reward block timestamp
            // so that ALL reward will be distributed.
            // however, if the first deposit is out of reward period, last reward block will be its block timestamp
            // in order to keep the multiplier = 0
            if (
                block.timestamp > _endTimestampOf(_campaignID, block.timestamp)
            ) {
                campaign.lastRewardTimestamp = block.timestamp;
            }
            return;
        }
        // @dev for each reward info
        for (uint256 i = 0; i < rewardInfo.length; ++i) {
            // @dev get multiplier based on current Block and rewardInfo's end block
            // multiplier will be a range of either (current block - campaign.lastRewardBlock)
            // or (reward info's endblock - campaign.lastRewardTimestamp) or 0
            uint256 multiplier = getMultiplier(
                campaign.lastRewardTimestamp,
                block.timestamp,
                rewardInfo[i].endTimestamp
            );
            if (multiplier == 0) continue;
            // @dev if currentTimestamp exceed end block, use end block as the last reward block
            // so that for the next iteration, previous endTimestamp will be used as the last reward block
            if (block.timestamp > rewardInfo[i].endTimestamp) {
                campaign.lastRewardTimestamp = rewardInfo[i].endTimestamp;
            } else {
                campaign.lastRewardTimestamp = block.timestamp;
            }
            campaign.accRewardPerShare +=
                ((multiplier * rewardInfo[i].rewardPerSec) *
                    campaign.precision) /
                campaign.totalStaked;
        }
    }

    // @notice Update reward variables for all campaigns. gas spending is HIGH in this method call, BE CAREFUL
    function massUpdateCampaigns() external nonReentrant {
        uint256 length = campaignInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updateCampaign(pid);
        }
    }

    function depositWithPermit(
        uint256 _campaignID,
        uint256 _amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        campaign.stakingToken.permit(
            msg.sender,
            address(this),
            _amount,
            deadline,
            v,
            r,
            s
        );
        _deposit(_campaignID, _amount);
    }

    // @notice Stake Staking tokens to TokenFarm
    function deposit(uint256 _campaignID, uint256 _amount)
        external
        nonReentrant
    {
        _deposit(_campaignID, _amount);
    }

    // @notice Stake Staking tokens to TokenFarm
    function _deposit(uint256 _campaignID, uint256 _amount) internal {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        _updateCampaign(_campaignID);
        if (user.amount > 0) {
            uint256 pending = ((user.amount * campaign.accRewardPerShare) /
                campaign.precision) - user.rewardDebt;
            if (pending > 0) {
                campaign.rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if (_amount > 0) {
            campaign.stakingToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount += _amount;
            campaign.totalStaked += _amount;
        }
        user.rewardDebt =
            (user.amount * campaign.accRewardPerShare) /
            campaign.precision;
        emit Deposit(msg.sender, _amount, _campaignID);
    }

    // @notice Withdraw Staking tokens from STAKING.
    function withdraw(uint256 _campaignID, uint256 _amount)
        external
        nonReentrant
    {
        _withdraw(_campaignID, _amount);
    }

    // @notice internal method for withdraw (withdraw and harvest method depend on this method)
    function _withdraw(uint256 _campaignID, uint256 _amount) internal {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        require(user.amount >= _amount, "withdraw::bad withdraw amount");
        _updateCampaign(_campaignID);
        uint256 pending = ((user.amount * campaign.accRewardPerShare) /
            campaign.precision) - user.rewardDebt;
        if (pending > 0) {
            campaign.rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if (_amount > 0) {
            user.amount -= _amount;
            campaign.stakingToken.safeTransfer(address(msg.sender), _amount);
            campaign.totalStaked -= _amount;
        }
        user.rewardDebt =
            (user.amount * campaign.accRewardPerShare) /
            campaign.precision;

        emit Withdraw(msg.sender, _amount, _campaignID);
    }

    // @notice method for harvest campaigns (used when the user want to claim their reward token based on specified campaigns)
    function harvest(uint256[] calldata _campaignIDs) external nonReentrant {
        for (uint256 i = 0; i < _campaignIDs.length; ++i) {
            _withdraw(_campaignIDs[i], 0);
        }
    }

    // @notice Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _campaignID) external nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        UserInfo storage user = userInfo[_campaignID][msg.sender];
        uint256 _amount = user.amount;
        campaign.totalStaked -= _amount;
        user.amount = 0;
        user.rewardDebt = 0;
        campaign.stakingToken.safeTransfer(address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _amount, _campaignID);
    }

    // @notice Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(
        uint256 _campaignID,
        uint256 _amount,
        address _beneficiary
    ) external onlyOwner nonReentrant {
        CampaignInfo storage campaign = campaignInfo[_campaignID];
        uint256 currentStakingPendingReward = _pendingReward(
            _campaignID,
            campaign.totalStaked,
            0
        );
        require(
            currentStakingPendingReward + _amount <= campaign.totalRewards,
            "emergencyRewardWithdraw::not enough reward token"
        );
        campaign.totalRewards -= _amount;
        campaign.rewardToken.safeTransfer(_beneficiary, _amount);
    }
}
