// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGovernanceToken {
    function locked__of(address _addr) external view returns (uint256);

    function locked__end(address _addr) external view returns (uint256);

    function voting_power_unlock_time(uint256 _value, uint256 _unlock_time)
        external
        view
        returns (uint256);

    function voting_power_locked_days(uint256 _value, uint256 _days)
        external
        view
        returns (uint256);

    function deposit_for(address _addr, uint256 _value) external;

    function create_lock(uint256 _value, uint256 _days) external;

    function increase_amount(uint256 _value) external;

    function increase_unlock_time(uint256 _days) external;

    function withdraw() external;
}

contract veSolarBeamToken is ERC20Burnable, IGovernanceToken, Ownable {
    using SafeERC20 for IERC20;

    address immutable burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 private _unlocked;

    uint256 public constant MINDAYS = 7;
    uint256 public constant MAXDAYS = 3 * 365;

    uint256 public constant MAXTIME = MAXDAYS * 1 days; // 3 years
    uint256 public constant MAX_WITHDRAWAL_PENALTY = 50000; // 50%
    uint256 public constant PRECISION = 100000; // 5 decimals

    IERC20 public lockedToken;
    uint256 public minLockedAmount;
    uint256 public earlyWithdrawPenaltyRate;

    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }

    mapping(address => LockedBalance) public locked;
    mapping(address => uint256) public mintedForLock;

    /* ========== MODIFIERS ========== */

    modifier lock() {
        require(_unlocked == 1, "LOCKED");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _lockedToken,
        uint256 _minLockedAmount
    ) ERC20(_name, _symbol) {
        lockedToken = IERC20(_lockedToken);
        minLockedAmount = _minLockedAmount;
        earlyWithdrawPenaltyRate = 3000; // 30%
        _unlocked = 1;
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function locked__of(address _addr)
        external
        view
        override
        returns (uint256)
    {
        return locked[_addr].amount;
    }

    function locked__end(address _addr)
        external
        view
        override
        returns (uint256)
    {
        return locked[_addr].end;
    }

    function voting_power_unlock_time(uint256 _value, uint256 _unlock_time)
        public
        view
        override
        returns (uint256)
    {
        uint256 _now = block.timestamp;
        if (_unlock_time <= _now) return 0;
        uint256 _lockedSeconds = _unlock_time - _now;
        if (_lockedSeconds >= MAXTIME) {
            return _getAmountOf(_value);
        }
        return (_getAmountOf(_value) * _lockedSeconds) / MAXTIME;
    }

    function voting_power_locked_days(uint256 _value, uint256 _days)
        public
        view
        override
        returns (uint256)
    {
        if (_days >= MAXDAYS) {
            return _getAmountOf(_value);
        }
        return (_getAmountOf(_value) * _days) / MAXDAYS;
    }

    function deposit_for(address _addr, uint256 _value) external override {
        require(_value >= minLockedAmount, "less than min amount");
        _deposit_for(_addr, _value, 0);
    }

    function create_lock(uint256 _value, uint256 _days) external override {
        require(_value >= minLockedAmount, "less than min amount");
        require(locked[_msgSender()].amount == 0, "Withdraw old tokens first");
        require(_days >= MINDAYS, "Voting lock can be 7 days min");
        require(_days <= MAXDAYS, "Voting lock can be 4 years max");
        _deposit_for(_msgSender(), _value, _days);
    }

    function increase_amount(uint256 _value) external override {
        require(_value >= minLockedAmount, "less than min amount");
        _deposit_for(_msgSender(), _value, 0);
    }

    function increase_unlock_time(uint256 _days) external override {
        require(_days >= MINDAYS, "Voting lock can be 7 days min");
        require(_days <= MAXDAYS, "Voting lock can be 4 years max");
        _deposit_for(_msgSender(), 0, _days);
    }

    function withdraw() external override lock {
        LockedBalance storage _locked = locked[_msgSender()];
        uint256 _now = block.timestamp;
        require(_locked.amount > 0, "Nothing to withdraw");
        require(_now >= _locked.end, "The lock didn't expire");
        uint256 _amount = _locked.amount;
        _locked.end = 0;
        _locked.amount = 0;
        _burn(_msgSender(), mintedForLock[_msgSender()]);
        mintedForLock[_msgSender()] = 0;
        IERC20(lockedToken).safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), _amount, _now);
    }

    // This will charge PENALTY if lock is not expired yet
    function emergencyWithdraw() external lock {
        LockedBalance storage _locked = locked[_msgSender()];
        uint256 _now = block.timestamp;
        require(_locked.amount > 0, "Nothing to withdraw");
        uint256 _amount = _locked.amount;
        if (_now < _locked.end) {
            uint256 _fee = (_amount * earlyWithdrawPenaltyRate) / PRECISION;
            _penalize(_fee);
            _amount = _amount - _fee;
        }
        _locked.end = 0;
        _locked.amount = 0;
        _burn(_msgSender(), mintedForLock[_msgSender()]);
        mintedForLock[_msgSender()] = 0;

        IERC20(lockedToken).safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), _amount, _now);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _getAmountOf(uint256 _amount) private view returns (uint256) {
        uint256 totalSolar = lockedToken.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        return (_amount * totalShares) / totalSolar;
    }

    function _deposit_for(
        address _addr,
        uint256 _value,
        uint256 _days
    ) internal lock {
        LockedBalance storage _locked = locked[_addr];
        uint256 _now = block.timestamp;
        uint256 _amount = _locked.amount;
        uint256 _end = _locked.end;
        uint256 _vp;
        if (_amount == 0) {
            _vp = voting_power_locked_days(_value, _days);
            _locked.amount = _value;
            _locked.end = _now + _days * 1 days;
        } else if (_days == 0) {
            _vp = voting_power_unlock_time(_value, _end);
            _locked.amount = _amount + _value;
        } else {
            require(
                _value == 0,
                "Cannot increase amount and extend lock in the same time"
            );
            _vp = voting_power_locked_days(_amount, _days);
            _locked.end = _end + _days * 1 days;
            require(
                _locked.end - _now <= MAXTIME,
                "Cannot extend lock to more than 4 years"
            );
        }
        require(_vp > 0, "No benefit to lock");
        if (_value > 0) {
            IERC20(lockedToken).safeTransferFrom(
                _msgSender(),
                address(this),
                _value
            );
        }
        _mint(_addr, _vp);
        mintedForLock[_addr] += _vp;

        emit Deposit(_addr, _locked.amount, _locked.end, _now);
    }

    function _penalize(uint256 _amount) internal {
        IERC20(lockedToken).safeTransfer(burnAddress, _amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinLockedAmount(uint256 _minLockedAmount) external onlyOwner {
        minLockedAmount = _minLockedAmount;
        emit MinLockedAmountSet(_minLockedAmount);
    }

    function setEarlyWithdrawPenaltyRate(uint256 _earlyWithdrawPenaltyRate)
        external
        onlyOwner
    {
        require(
            _earlyWithdrawPenaltyRate <= MAX_WITHDRAWAL_PENALTY,
            "withdrawal penalty is too high"
        ); // <= 50%
        earlyWithdrawPenaltyRate = _earlyWithdrawPenaltyRate;
        emit EarlyWithdrawPenaltySet(_earlyWithdrawPenaltyRate);
    }

    /* =============== EVENTS ==================== */
    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 locktime,
        uint256 timestamp
    );
    event Withdraw(address indexed provider, uint256 value, uint256 timestamp);
    event PenaltyCollectorSet(address indexed addr);
    event EarlyWithdrawPenaltySet(uint256 indexed penalty);
    event MinLockedAmountSet(uint256 indexed amount);
}
