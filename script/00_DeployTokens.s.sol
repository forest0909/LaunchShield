// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";

import {MockLaunchToken} from "../src/MockLaunchToken.sol";
import {XLayerScript} from "./base/XLayerScript.sol";

contract DeployTokensScript is XLayerScript {
    uint256 internal constant DEFAULT_INITIAL_SUPPLY = 1_000_000e18;

    function run() external returns (MockLaunchToken launchToken, MockLaunchToken quoteToken) {
        _requireXLayerDeployments();
        address deployer = _deployer();
        uint256 initialSupply = vm.envOr("INITIAL_SUPPLY", DEFAULT_INITIAL_SUPPLY);

        vm.startBroadcast();
        launchToken = new MockLaunchToken("LaunchShield Token", "XSH", deployer, initialSupply);
        quoteToken = new MockLaunchToken("Mock USD Coin", "mUSDC", deployer, initialSupply);
        vm.stopBroadcast();

        console2.log("XSH token:", address(launchToken));
        console2.log("mUSDC token:", address(quoteToken));
    }
}
