// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

contract LaunchShieldHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    uint24 public constant BASE_FEE = 3000;
    uint24 public constant GUARDED_FEE = 10000;
    uint256 public constant LAUNCH_DURATION = 30 minutes;
    uint256 public constant GUARDED_COOLDOWN = 10 minutes;
    int24 public constant NORMAL_MAX_TICK_MOVE = 295;
    int24 public constant GUARDED_MAX_TICK_MOVE = 148;
    int24 public constant VOLATILITY_TRIGGER_TICK_MOVE = 199;

    error MovementCapExceeded(int24 observedTickMove, int24 allowedTickMove);

    event GuardedModeActivated(PoolId indexed poolId, int24 tickMove, uint64 guardedUntil);

    struct PoolProtection {
        uint64 launchTime;
        uint64 guardedUntil;
        int24 preSwapTick;
        bool initialized;
    }

    mapping(PoolId poolId => PoolProtection state) public protection;

    constructor(IPoolManager manager) BaseHook(manager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory permissions) {
        permissions.afterInitialize = true;
        permissions.beforeSwap = true;
        permissions.afterSwap = true;
    }

    function isGuarded(PoolId poolId) public view returns (bool) {
        return protection[poolId].guardedUntil > block.timestamp;
    }

    function effectiveFee(PoolId poolId) public view returns (uint24) {
        return isGuarded(poolId) ? GUARDED_FEE : BASE_FEE;
    }

    function launchProtectionActive(PoolId poolId) public view returns (bool) {
        PoolProtection storage state = protection[poolId];
        return state.initialized && block.timestamp < uint256(state.launchTime) + LAUNCH_DURATION;
    }

    function effectiveMovementCap(PoolId poolId) public view returns (int24) {
        return isGuarded(poolId) ? GUARDED_MAX_TICK_MOVE : NORMAL_MAX_TICK_MOVE;
    }

    function _afterInitialize(address, PoolKey calldata key, uint160, int24) internal override returns (bytes4) {
        PoolProtection storage state = protection[key.toId()];
        state.launchTime = uint64(block.timestamp);
        state.initialized = true;
        return BaseHook.afterInitialize.selector;
    }

    function _beforeSwap(address, PoolKey calldata key, SwapParams calldata, bytes calldata)
        internal
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        PoolId poolId = key.toId();
        (, int24 tick,,) = poolManager.getSlot0(poolId);
        protection[poolId].preSwapTick = tick;

        uint24 feeOverride = effectiveFee(poolId) | LPFeeLibrary.OVERRIDE_FEE_FLAG;
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, feeOverride);
    }

    function _afterSwap(address, PoolKey calldata key, SwapParams calldata, BalanceDelta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        PoolId poolId = key.toId();
        PoolProtection storage state = protection[poolId];
        (, int24 tickAfter,,) = poolManager.getSlot0(poolId);
        int24 tickMove = _absoluteTickMove(state.preSwapTick, tickAfter);

        if (launchProtectionActive(poolId)) {
            int24 movementCap = effectiveMovementCap(poolId);
            if (tickMove > movementCap) revert MovementCapExceeded(tickMove, movementCap);
        }

        if (tickMove >= VOLATILITY_TRIGGER_TICK_MOVE) {
            state.guardedUntil = uint64(block.timestamp + GUARDED_COOLDOWN);
            emit GuardedModeActivated(poolId, tickMove, state.guardedUntil);
        }

        return (BaseHook.afterSwap.selector, 0);
    }

    function _absoluteTickMove(int24 fromTick, int24 toTick) internal pure returns (int24) {
        int24 delta = toTick - fromTick;
        return delta < 0 ? -delta : delta;
    }
}
