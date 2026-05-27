// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {LPFeeLibrary} from "@uniswap/v4-core/src/libraries/LPFeeLibrary.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

import {XLayerV4Addresses} from "../../src/XLayerV4Addresses.sol";

abstract contract XLayerScript is Script {
    error MissingContractCode(address target);
    error TokensMustBeDistinct();
    error UnsupportedChain(uint256 chainId);
    error ZeroAddress(string name);

    int24 internal constant TICK_SPACING = 60;

    function _requireXLayerDeployments() internal view {
        if (block.chainid != XLayerV4Addresses.CHAIN_ID) revert UnsupportedChain(block.chainid);

        _requireCode(XLayerV4Addresses.POOL_MANAGER);
        _requireCode(XLayerV4Addresses.POSITION_MANAGER);
        _requireCode(XLayerV4Addresses.STATE_VIEW);
        _requireCode(XLayerV4Addresses.PERMIT2);
        _requireCode(XLayerV4Addresses.CREATE2_FACTORY);
    }

    function _deployer() internal view returns (address deployer) {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        if (deployer == address(0)) revert ZeroAddress("DEPLOYER_ADDRESS");
    }

    function _poolKey(address tokenA, address tokenB, address hookAddress) internal pure returns (PoolKey memory key) {
        if (tokenA == tokenB) revert TokensMustBeDistinct();
        if (hookAddress == address(0)) revert ZeroAddress("HOOK_ADDRESS");

        (Currency currency0, Currency currency1) = tokenA < tokenB
            ? (Currency.wrap(tokenA), Currency.wrap(tokenB))
            : (Currency.wrap(tokenB), Currency.wrap(tokenA));

        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: LPFeeLibrary.DYNAMIC_FEE_FLAG,
            tickSpacing: TICK_SPACING,
            hooks: IHooks(hookAddress)
        });
    }

    function _requireCode(address target) internal view {
        if (target.code.length == 0) revert MissingContractCode(target);
    }
}
