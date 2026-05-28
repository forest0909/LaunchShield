// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console2} from "forge-std/console2.sol";

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {StateView} from "@uniswap/v4-periphery/src/lens/StateView.sol";
import {Permit2Deployer} from "hookmate/artifacts/Permit2.sol";
import {V4PoolManagerDeployer} from "hookmate/artifacts/V4PoolManager.sol";
import {V4PositionManagerDeployer} from "hookmate/artifacts/V4PositionManager.sol";
import {V4RouterDeployer} from "hookmate/artifacts/V4Router.sol";

import {XLayerScript} from "./base/XLayerScript.sol";

contract DeployTestnetV4Script is XLayerScript {
    uint256 internal constant UNSUBSCRIBE_GAS_LIMIT = 300_000;

    function run()
        external
        returns (address permit2, address poolManager, address positionManager, address stateView, address demoRouter)
    {
        _requireXLayerTestnet();
        address deployer = _deployer();

        vm.startBroadcast();
        permit2 = _configuredDeployedAddress("PERMIT2");
        if (permit2 == address(0)) permit2 = Permit2Deployer.deploy();

        poolManager = _configuredDeployedAddress("POOL_MANAGER");
        if (poolManager == address(0)) poolManager = V4PoolManagerDeployer.deploy(deployer);

        positionManager = _configuredDeployedAddress("POSITION_MANAGER");
        if (positionManager == address(0)) {
            positionManager =
                V4PositionManagerDeployer.deploy(poolManager, permit2, UNSUBSCRIBE_GAS_LIMIT, address(0), address(0));
        }

        stateView = _configuredDeployedAddress("STATE_VIEW");
        if (stateView == address(0)) stateView = address(new StateView(IPoolManager(poolManager)));

        demoRouter = _configuredDeployedAddress("DEMO_ROUTER");
        if (demoRouter == address(0)) demoRouter = V4RouterDeployer.deploy(poolManager, permit2);
        vm.stopBroadcast();

        console2.log("PERMIT2:", permit2);
        console2.log("POOL_MANAGER:", poolManager);
        console2.log("POSITION_MANAGER:", positionManager);
        console2.log("STATE_VIEW:", stateView);
        console2.log("DEMO_ROUTER:", demoRouter);
    }

    function _configuredDeployedAddress(string memory name) internal view returns (address target) {
        target = vm.envOr(name, address(0));
        if (target != address(0)) _requireCode(target);
    }
}
