// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./libraries/IBoringERC20.sol";

interface ISolarDistributorV2 {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IBoringERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this poolInfo. SOLAR to distribute per block.
        uint256 lastRewardTimestamp; // Last block timestamp that SOLAR distribution occurs.
        uint256 accSolarPerShare; // Accumulated SOLAR per share, times 1e12. See below.
    }

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function totalAllocPoint() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;
}
