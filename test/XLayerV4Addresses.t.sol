// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {XLayerV4Addresses} from "../src/XLayerV4Addresses.sol";

contract XLayerV4AddressesTest is Test {
    function testPublishesVerifiedXLayerMainnetDeployments() public pure {
        assertEq(XLayerV4Addresses.MAINNET_CHAIN_ID, 196);
        assertEq(XLayerV4Addresses.POOL_MANAGER, 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32);
        assertEq(XLayerV4Addresses.POSITION_MANAGER, 0xcF1EAFC6928dC385A342E7C6491d371d2871458b);
        assertEq(XLayerV4Addresses.STATE_VIEW, 0x76Fd297e2D437cd7f76d50F01AfE6160f86e9990);
        assertEq(XLayerV4Addresses.UNIVERSAL_ROUTER, 0xDa00aE15d3A71466517129255255db7c0c0956d3);
        assertEq(XLayerV4Addresses.PERMIT2, 0x000000000022D473030F116dDEE9F6B43aC78BA3);
        assertEq(XLayerV4Addresses.CREATE2_FACTORY, 0x4e59b44847b379578588920cA78FbF26c0B4956C);
        assertEq(XLayerV4Addresses.HOOKMATE_DEMO_ROUTER, 0xE4e6CAdE3E2a67F16A5d867C44e1e7Df02f0fc03);
    }

    function testPublishesXLayerTestnetChainId() public pure {
        assertEq(XLayerV4Addresses.TESTNET_CHAIN_ID, 1952);
    }
}
