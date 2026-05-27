// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {CustomRevert} from "@uniswap/v4-core/src/libraries/CustomRevert.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {Vm} from "forge-std/Vm.sol";

import {EasyPosm} from "./utils/libraries/EasyPosm.sol";
import {BaseTest} from "./utils/BaseTest.sol";
import {LaunchShieldHook} from "../src/LaunchShieldHook.sol";

contract LaunchShieldHookTest is BaseTest {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    Currency internal currency0;
    Currency internal currency1;
    PoolKey internal poolKey;
    PoolId internal poolId;
    LaunchShieldHook internal hook;

    function setUp() public {
        deployArtifactsAndLabel();
        (currency0, currency1) = deployCurrencyPair();

        address flags = address(
            uint160(Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG) ^ (0x4C53 << 144)
        );
        deployCodeTo("LaunchShieldHook.sol:LaunchShieldHook", abi.encode(poolManager), flags);
        hook = LaunchShieldHook(flags);

        poolKey = PoolKey(currency0, currency1, LPFeeLibrary.DYNAMIC_FEE_FLAG, 60, IHooks(hook));
        poolId = poolKey.toId();
        poolManager.initialize(poolKey, Constants.SQRT_PRICE_1_1);

        int24 tickLower = TickMath.minUsableTick(poolKey.tickSpacing);
        int24 tickUpper = TickMath.maxUsableTick(poolKey.tickSpacing);
        uint128 liquidity = 100e18;
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            Constants.SQRT_PRICE_1_1,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            liquidity
        );
        positionManager.mint(
            poolKey,
            tickLower,
            tickUpper,
            liquidity,
            amount0 + 1,
            amount1 + 1,
            address(this),
            block.timestamp,
            Constants.ZERO_BYTES
        );
    }

    function testPoolInitializationStartsLaunchProtection() public view {
        (uint64 launchTime,,, bool initialized) = hook.protection(poolId);

        assertTrue(initialized);
        assertEq(uint256(launchTime), block.timestamp);
        assertTrue(hook.launchProtectionActive(poolId));
        assertEq(hook.effectiveFee(poolId), hook.BASE_FEE());
    }

    function testVolatileAcceptedSwapActivatesGuardedModeForNextTrade() public {
        _swap(12e17);

        assertTrue(hook.isGuarded(poolId));
        assertEq(hook.effectiveFee(poolId), hook.GUARDED_FEE());
        assertEq(_swapAndReadFee(1e17), hook.GUARDED_FEE());
    }

    function testLargeSwapDuringLaunchProtectionRevertsWithoutChangingTick() public {
        int24 tickBefore = _tick();

        _assertMovementCapRevert(2e18);

        assertEq(_tick(), tickBefore);
    }

    function testSmallSwapChargesBaseFeeAndStaysNormal() public {
        assertEq(_swapAndReadFee(1e17), hook.BASE_FEE());
        assertFalse(hook.isGuarded(poolId));
    }

    function testGuardedModeUsesTighterMovementCap() public {
        _swap(12e17);
        uint64 guardedUntilBefore = _guardedUntil();
        int24 tickBefore = _tick();

        _assertMovementCapRevert(1e18);

        assertEq(_tick(), tickBefore);
        assertEq(_guardedUntil(), guardedUntilBefore);
    }

    function testCooldownExpiryRestoresBaseFee() public {
        _swap(12e17);
        vm.warp(_guardedUntil() + 1);

        assertFalse(hook.isGuarded(poolId));
        assertEq(_swapAndReadFee(1e17), hook.BASE_FEE());
    }

    function testAfterLaunchExpiryMovementCapIsDisabledButVolatilityFeeRemains() public {
        vm.warp(block.timestamp + hook.LAUNCH_DURATION() + 1);

        _swap(2e18);

        assertTrue(hook.isGuarded(poolId));
        assertEq(hook.effectiveFee(poolId), hook.GUARDED_FEE());
    }

    function _swap(uint256 amountIn) internal {
        swapRouter.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            zeroForOne: true,
            poolKey: poolKey,
            hookData: Constants.ZERO_BYTES,
            receiver: address(this),
            deadline: block.timestamp + 1
        });
    }

    function swapForRevertAssertion(uint256 amountIn) external {
        require(msg.sender == address(this));
        _swap(amountIn);
    }

    function _tick() internal view returns (int24 tick) {
        (, tick,,) = poolManager.getSlot0(poolId);
    }

    function _guardedUntil() internal view returns (uint64 guardedUntil) {
        (, guardedUntil,,) = hook.protection(poolId);
    }

    function _swapAndReadFee(uint256 amountIn) internal returns (uint24 fee) {
        vm.recordLogs();
        _swap(amountIn);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 swapSignature = keccak256("Swap(bytes32,address,int128,int128,uint160,uint128,int24,uint24)");

        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter == address(poolManager) && logs[i].topics[0] == swapSignature) {
                (,,,,, fee) = abi.decode(logs[i].data, (int128, int128, uint160, uint128, int24, uint24));
                return fee;
            }
        }

        fail("PoolManager swap event missing");
    }

    function _assertMovementCapRevert(uint256 amountIn) internal {
        try this.swapForRevertAssertion(amountIn) {
            fail("Expected movement cap revert");
        } catch (bytes memory revertData) {
            assertEq(bytes4(revertData), CustomRevert.WrappedError.selector);
            (, bytes4 hookSelector, bytes memory reason,) =
                abi.decode(_stripSelector(revertData), (address, bytes4, bytes, bytes));

            assertEq(hookSelector, IHooks.afterSwap.selector);
            assertEq(bytes4(reason), LaunchShieldHook.MovementCapExceeded.selector);
        }
    }

    function _stripSelector(bytes memory revertData) internal pure returns (bytes memory payload) {
        payload = new bytes(revertData.length - 4);
        for (uint256 i = 4; i < revertData.length; i++) {
            payload[i - 4] = revertData[i];
        }
    }
}
