// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



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
     * by making the `nonReentrant` function external, and make it call a
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



// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ISolarERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
}


contract SolarVault is Ownable, ReentrancyGuard {
    address constant _trustedForwarder =
        0x0D0b4862F5FfA3A47D04DDf0351356d20C830460; //Trusted forwarder

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 lastInteraction; // Last time when user deposited or claimed rewards, renewing the lock
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract
        uint256 allocPoint; // How many allocation points assigned to this pool. Solar to distribute per block.
        uint256 lastRewardBlock; // Last block number that Solar distribution occurs.
        uint256 accSolarPerShare; // Accumulated Solar per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 harvestInterval; // Harvest interval in seconds
        uint256 totalLp; // Total token in Pool
        uint256 lockupDuration; // Amount of time the participant will be locked in the pool after depositing or claiming rewards
    }

    ISolarERC20 public solar;

    // The operator can only update EmissionRate and AllocPoint to protect tokenomics
    //i.e some wrong setting and a pools get too much allocation accidentally
    address private _operator;

    // Dev address.
    address public devAddress;

    // Deposit Fee address
    address public feeAddress;

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

    // Control support for EIP-2771 Meta Transactions
    bool public metaTxnsEnabled = false;

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
    event OperatorTransferred(
        address indexed previousOperator,
        address indexed newOperator
    );
    event DevAddressChanged(
        address indexed caller,
        address oldAddress,
        address newAddress
    );
    event FeeAddressChanged(
        address indexed caller,
        address oldAddress,
        address newAddress
    );
    event AllocPointsUpdated(
        address indexed caller,
        uint256 previousAmount,
        uint256 newAmount
    );
    event MetaTxnsEnabled(address indexed caller);
    event MetaTxnsDisabled(address indexed caller);

    modifier onlyOperator() {
        require(
            _operator == msg.sender,
            "Operator: caller is not the operator"
        );
        _;
    }

    constructor(ISolarERC20 _solar, uint256 _solarPerBlock) {
        //StartBlock always many years later from contract construct, will be set later in StartFarming function
        startBlock = block.number + (10 * 365 * 24 * 60 * 60);

        solar = _solar;
        solarPerBlock = _solarPerBlock;

        devAddress = msg.sender;
        feeAddress = msg.sender;
        _operator = msg.sender;
        emit OperatorTransferred(address(0), _operator);
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return metaTxnsEnabled && forwarder == _trustedForwarder;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    function operator() public view returns (address) {
        return _operator;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    function transferOperator(address newOperator) public onlyOperator {
        require(
            newOperator != address(0),
            "TransferOperator: new operator is the zero address"
        );
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }

    // Set farming start, can call only once
    function startFarming() public onlyOwner {
        require(block.number < startBlock, "Error: farm started already");

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
        IERC20 _lpToken,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        uint256 _lockupDuration,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE,
            "Add: deposit fee too high"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "Add: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accSolarPerShare: 0,
                depositFeeBP: _depositFeeBP,
                harvestInterval: _harvestInterval,
                totalLp: 0,
                lockupDuration: _lockupDuration
            })
        );
    }

    // View function to see pending Solar on frontend.
    function pendingSolar(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSolarPerShare = pool.accSolarPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 solarReward = multiplier
                .mul(solarPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accSolarPerShare = accSolarPerShare.add(
                solarReward.mul(1e12).div(lpSupply)
            );
        }

        uint256 pending = user.amount.mul(accSolarPerShare).div(1e12).sub(
            user.rewardDebt
        );
        return pending.add(user.rewardLockedUp);
    }

    // View function to see when user will be unlocked from pool
    function userLockedUntil(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];

        return user.lastInteraction + pool.lockupDuration;
    }

    // View function to see if user can harvest Solar.
    function canHarvest(uint256 _pid, address _user)
        public
        view
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
    function updatePool(uint256 _pid) public {
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
        uint256 solarReward = multiplier
            .mul(solarPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        solar.mint(devAddress, solarReward.div(10));
        solar.mint(address(this), solarReward);

        pool.accSolarPerShare = pool.accSolarPerShare.add(
            solarReward.mul(1e12).div(pool.totalLp)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to SolarVault for Solar allocation
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(
            block.number >= startBlock,
            "SolarVault: cannot deposit before farming start"
        );

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        updatePool(_pid);

        payOrLockupPendingSolar(_pid);

        if (_amount > 0) {
            uint256 beforeDeposit = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(_msgSender(), address(this), _amount);
            uint256 afterDeposit = pool.lpToken.balanceOf(address(this));

            _amount = afterDeposit.sub(beforeDeposit);

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);

                _amount = _amount.sub(depositFee);
            }

            user.amount = user.amount.add(_amount);
            pool.totalLp = pool.totalLp.add(_amount);

            if (address(pool.lpToken) == address(solar)) {
                totalSolarInPools = totalSolarInPools.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accSolarPerShare).div(1e12);
        user.lastInteraction = block.timestamp;
        emit Deposit(_msgSender(), _pid, _amount);
    }

    // Withdraw tokens
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        //this will make sure that user can only withdraw from his pool
        require(user.amount >= _amount, "Withdraw: user amount is not enough");

        //Cannot withdraw more than pool's balance
        require(pool.totalLp >= _amount, "Withdraw: pool total is not enough");

        //Cannot withdraw before lock time
        require(
            block.timestamp > user.lastInteraction + pool.lockupDuration,
            "Withdraw: you cannot withdraw yet"
        );

        updatePool(_pid);

        payOrLockupPendingSolar(_pid);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalLp = pool.totalLp.sub(_amount);
            if (address(pool.lpToken) == address(solar)) {
                totalSolarInPools = totalSolarInPools.sub(_amount);
            }
            pool.lpToken.safeTransfer(_msgSender(), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSolarPerShare).div(1e12);
        user.lastInteraction = block.timestamp;
        emit Withdraw(_msgSender(), _pid, _amount);
    }

    // Pay or lockup pending Solar.
    function payOrLockupPendingSolar(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        if (user.nextHarvestUntil == 0 && block.number >= startBlock) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accSolarPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (canHarvest(_pid, _msgSender())) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(
                    user.rewardLockedUp
                );
                user.rewardLockedUp = 0;
                user.lastInteraction = block.timestamp;
                user.nextHarvestUntil = block.timestamp.add(
                    pool.harvestInterval
                );

                // send rewards
                safeSolarTransfer(_msgSender(), totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            user.lastInteraction = block.timestamp;
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(_msgSender(), _pid, pending);
        }
    }

    // Safe Solar transfer function, just in case if rounding error causes pool do not have enough Solar.
    function safeSolarTransfer(address _to, uint256 _amount) internal {
        if (solar.balanceOf(address(this)) > totalSolarInPools) {
            //SolarBal = total Solar in SolarVault - total Solar in Solar pools, this will make sure that SolarVault never transfer rewards from deposited Solar pools
            uint256 SolarBal = solar.balanceOf(address(this)).sub(
                totalSolarInPools
            );
            if (_amount >= SolarBal) {
                solar.transfer(_to, SolarBal);
            } else if (_amount > 0) {
                solar.transfer(_to, _amount);
            }
        }
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(_msgSender() == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");

        emit DevAddressChanged(_msgSender(), devAddress, _devAddress);

        devAddress = _devAddress;
    }

    function setFeeAddress(address _feeAddress) public {
        require(_msgSender() == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");

        emit FeeAddressChanged(_msgSender(), feeAddress, _feeAddress);

        feeAddress = _feeAddress;
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _solarPerBlock) public onlyOperator {
        massUpdatePools();

        emit EmissionRateUpdated(msg.sender, solarPerBlock, _solarPerBlock);
        solarPerBlock = _solarPerBlock;
    }

    function updateAllocPoint(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOperator {
        if (_withUpdate) {
            massUpdatePools();
        }

        emit AllocPointsUpdated(
            _msgSender(),
            poolInfo[_pid].allocPoint,
            _allocPoint
        );

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Enable support for meta transactions
    function enableMetaTxns() public onlyOperator {
        require(
            !metaTxnsEnabled,
            "SolarVault: meta transactions are already enabled"
        );

        metaTxnsEnabled = true;
        emit MetaTxnsEnabled(_msgSender());
    }

    // Disable support for meta transactions
    function disableMetaTxns() public onlyOperator {
        require(
            metaTxnsEnabled,
            "SolarVault: meta transactions are already disabled"
        );

        metaTxnsEnabled = false;
        emit MetaTxnsDisabled(_msgSender());
    }
}



/** @title ICommonEclipse
 * @notice It is an interface for CommonEclipse.sol
 */
abstract contract ICommonEclipse {
    /**
     * @notice It sets parameters for pool
     * @param _offeringAmountPool: offering amount (in tokens)
     * @param _raisingAmountPool: raising amount (in LP tokens)
     * @param _baseLimitInLP: base limit per user (in LP tokens)
     * @param _hasTax: if the pool has a tax
     * @param _pid: poolId
     * @dev This function is only callable by owner.
     */
    function setPool(
        uint256 _offeringAmountPool,
        uint256 _raisingAmountPool,
        uint256 _baseLimitInLP,
        bool _hasTax,
        uint8 _pid
    ) external virtual;

    /**
     * @notice It allows users to deposit LP tokens to pool
     * @param _amount: the number of LP token used (18 decimals)
     * @param _pid: pool id
     */
    function depositPool(uint256 _amount, uint8 _pid) external virtual;

    /**
     * @notice It allows users to harvest from pool
     * @param _pid: pool id
     * @param _harvestPeriod: chosen harvest period to claim
     */
    function harvestPool(uint8 _pid, uint8 _harvestPeriod) external virtual;

    /**
     * @notice It allows owner to update start and end blocks of the sale
     * @param _startBlock: block number sale starts
     * @param _endBlock: block number sale ends
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _endBlock)
        external
        virtual;

    /**
     * @notice It allows owner to set the multiplier information
     * @param _multipliers: encoded multipliers for zero, seven and thirty day vaults
     * @dev encoded args are (uint8,uint8,uint8,uint8[2][3],uint8[2][3],uint8[2][3])
     * (0 decimals)
     */
    function setMultipliers(bytes memory _multipliers) public virtual;

    /**
     * @notice It allows owner to set the threshold for eligibility
     * @param _eligibilityThreshold: amount of solar staked in vaults to be eligibile
     */
    function setEligibilityThreshold(uint256 _eligibilityThreshold)
        public
        virtual;

    /**
     * @notice It allows the admin to withdraw funds
     * @param _lpAmount: the number of LP token to withdraw (18 decimals)
     * @param _offerAmount: the number of offering amount to withdraw
     * @dev This function is only callable by owner.
     */
    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount)
        external
        virtual;

    /**
     * @notice It returns the tax overflow rate calculated for a pool
     * @dev 100,000,000,000 means 0.1 (10%) / 1 means 0.0000000000001 (0.0000001%) / 1,000,000,000,000 means 1 (100%)
     * @param _pid: poolId
     * @return It returns the tax percentage
     */
    function viewPoolTaxRateOverflow(uint256 _pid)
        external
        virtual
        returns (uint256);

    /**
     * @notice External view function to see user allocations for both pools
     * @param _user: user address
     * @param _pids[]: array of pids
     */
    function viewUserAllocationPools(address _user, uint8[] calldata _pids)
        external
        virtual
        returns (uint256[] memory);

    /**
     * @notice External view function to see user offering and refunding amounts for both pools
     * @param _user: user address
     * @param _pids: array of pids
     */
    function viewUserOfferingAndRefundingAmountsForPools(
        address _user,
        uint8[] calldata _pids
    ) external virtual returns (uint256[3][] memory);

    /**
     * @notice It allows users to withdraw LP tokens to pool
     * @param _amount: the number of LP token used (18 decimals)
     * @param _pid: pool id
     */
    function withdrawPool(uint256 _amount, uint8 _pid) external virtual;

    /**
     * @notice It allows the admin to end sale and start claim
     * @dev This function is only callable by owner.
     */
    function enableClaim() external virtual;
}


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
