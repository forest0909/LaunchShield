// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {IUniswapV4Router04} from "hookmate/interfaces/router/IUniswapV4Router04.sol";

import {XLayerScript} from "./base/XLayerScript.sol";

contract DemoSwapScript is XLayerScript {
    error InputTokenNotInPool(address inputToken);

    uint256 internal constant DEFAULT_SWAP_AMOUNT = 0.1e18;

    function run() external {
        _requireXLayerDeployments();
        address deployer = _deployer();
        address routerAddress = _demoRouter();
        address inputToken = vm.envAddress("INPUT_TOKEN");
        PoolKey memory poolKey =
            _poolKey(vm.envAddress("TOKEN_A"), vm.envAddress("TOKEN_B"), vm.envAddress("HOOK_ADDRESS"));
        uint256 amountIn = vm.envOr("SWAP_AMOUNT", DEFAULT_SWAP_AMOUNT);

        _requireCode(routerAddress);
        bool zeroForOne;
        if (inputToken == Currency.unwrap(poolKey.currency0)) {
            zeroForOne = true;
        } else if (inputToken == Currency.unwrap(poolKey.currency1)) {
            zeroForOne = false;
        } else {
            revert InputTokenNotInPool(inputToken);
        }

        vm.startBroadcast();
        IERC20(inputToken).approve(routerAddress, amountIn);
        IUniswapV4Router04(payable(routerAddress))
            .swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            zeroForOne: zeroForOne,
            poolKey: poolKey,
            hookData: bytes(""),
            receiver: deployer,
            deadline: block.timestamp + 5 minutes
        });
        vm.stopBroadcast();

        console2.log("Swap amount in:", amountIn);
    }
}
