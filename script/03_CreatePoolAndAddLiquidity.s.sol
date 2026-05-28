// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPoolInitializer_v4} from "@uniswap/v4-periphery/src/interfaces/IPoolInitializer_v4.sol";
import {Actions} from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {XLayerScript} from "./base/XLayerScript.sol";

contract CreatePoolAndAddLiquidityScript is XLayerScript {
    using PoolIdLibrary for PoolKey;

    uint160 internal constant STARTING_PRICE = 1 << 96;
    uint256 internal constant DEFAULT_INITIAL_LIQUIDITY = 100e18;

    function run() external returns (PoolKey memory poolKey) {
        _requireXLayerDeployments();
        address deployer = _deployer();
        poolKey = _poolKey(vm.envAddress("TOKEN_A"), vm.envAddress("TOKEN_B"), vm.envAddress("HOOK_ADDRESS"));

        _requireCode(Currency.unwrap(poolKey.currency0));
        _requireCode(Currency.unwrap(poolKey.currency1));
        _requireCode(address(poolKey.hooks));

        uint128 liquidity = _configuredLiquidity();

        vm.startBroadcast();
        _approvePositionManager(poolKey);
        IPositionManager(_positionManager()).multicall(_poolInitializationCalls(poolKey, liquidity, deployer));
        vm.stopBroadcast();

        console2.log("Initial liquidity:", liquidity);
        console2.log("Currency0:", Currency.unwrap(poolKey.currency0));
        console2.log("Currency1:", Currency.unwrap(poolKey.currency1));
        console2.log("Pool ID:");
        console2.logBytes32(PoolId.unwrap(poolKey.toId()));
    }

    function _configuredLiquidity() internal view returns (uint128 liquidity) {
        uint256 configuredLiquidity = vm.envOr("INITIAL_LIQUIDITY", DEFAULT_INITIAL_LIQUIDITY);
        require(configuredLiquidity <= type(uint128).max, "liquidity too large");
        liquidity = uint128(configuredLiquidity);
    }

    function _approvePositionManager(PoolKey memory poolKey) internal {
        address permit2Address = _permit2();
        address positionManager = _positionManager();

        IERC20(Currency.unwrap(poolKey.currency0)).approve(permit2Address, type(uint256).max);
        IERC20(Currency.unwrap(poolKey.currency1)).approve(permit2Address, type(uint256).max);
        IPermit2 permit2 = IPermit2(permit2Address);
        permit2.approve(Currency.unwrap(poolKey.currency0), positionManager, type(uint160).max, type(uint48).max);
        permit2.approve(Currency.unwrap(poolKey.currency1), positionManager, type(uint160).max, type(uint48).max);
    }

    function _poolInitializationCalls(PoolKey memory poolKey, uint128 liquidity, address recipient)
        internal
        view
        returns (bytes[] memory calls)
    {
        int24 tickLower = TickMath.minUsableTick(poolKey.tickSpacing);
        int24 tickUpper = TickMath.maxUsableTick(poolKey.tickSpacing);
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            STARTING_PRICE, TickMath.getSqrtPriceAtTick(tickLower), TickMath.getSqrtPriceAtTick(tickUpper), liquidity
        );
        require(amount0 < type(uint128).max && amount1 < type(uint128).max, "token amount too large");

        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION), uint8(Actions.SETTLE_PAIR), uint8(Actions.SWEEP), uint8(Actions.SWEEP)
        );
        bytes[] memory mintParams = new bytes[](4);
        mintParams[0] = abi.encode(
            poolKey, tickLower, tickUpper, liquidity, uint128(amount0 + 1), uint128(amount1 + 1), recipient, bytes("")
        );
        mintParams[1] = abi.encode(poolKey.currency0, poolKey.currency1);
        mintParams[2] = abi.encode(poolKey.currency0, recipient);
        mintParams[3] = abi.encode(poolKey.currency1, recipient);

        calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(IPoolInitializer_v4.initializePool.selector, poolKey, STARTING_PRICE);
        calls[1] = abi.encodeWithSelector(
            IPositionManager.modifyLiquidities.selector, abi.encode(actions, mintParams), block.timestamp + 1 hours
        );
    }
}
