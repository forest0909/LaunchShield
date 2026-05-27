// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";

import {V4RouterDeployer} from "hookmate/artifacts/V4Router.sol";

import {XLayerV4Addresses} from "../src/XLayerV4Addresses.sol";
import {XLayerScript} from "./base/XLayerScript.sol";

/// @notice Resolves a simple demo router; this is not the official Uniswap Universal Router.
contract DeployDemoRouterScript is XLayerScript {
    function run() external returns (address router) {
        _requireXLayerDeployments();
        router = XLayerV4Addresses.HOOKMATE_DEMO_ROUTER;

        if (router.code.length == 0) {
            vm.startBroadcast();
            router = V4RouterDeployer.deploy(XLayerV4Addresses.POOL_MANAGER, XLayerV4Addresses.PERMIT2);
            vm.stopBroadcast();

            require(router == XLayerV4Addresses.HOOKMATE_DEMO_ROUTER, "unexpected router address");
            console2.log("Deployed LaunchShield demo router:", router);
        } else {
            console2.log("Reusing LaunchShield demo router:", router);
        }
    }
}
