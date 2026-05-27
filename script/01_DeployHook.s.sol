// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

import {LaunchShieldHook} from "../src/LaunchShieldHook.sol";
import {XLayerV4Addresses} from "../src/XLayerV4Addresses.sol";
import {XLayerScript} from "./base/XLayerScript.sol";

contract DeployHookScript is XLayerScript {
    function run() external returns (LaunchShieldHook hook) {
        _requireXLayerDeployments();

        uint160 flags = uint160(Hooks.AFTER_INITIALIZE_FLAG | Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        bytes memory constructorArgs = abi.encode(IPoolManager(XLayerV4Addresses.POOL_MANAGER));
        (address predictedAddress, bytes32 salt) = HookMiner.find(
            XLayerV4Addresses.CREATE2_FACTORY, flags, type(LaunchShieldHook).creationCode, constructorArgs
        );

        vm.startBroadcast();
        hook = new LaunchShieldHook{salt: salt}(IPoolManager(XLayerV4Addresses.POOL_MANAGER));
        vm.stopBroadcast();

        require(address(hook) == predictedAddress, "unexpected hook address");
        console2.log("LaunchShield hook:", address(hook));
    }
}
