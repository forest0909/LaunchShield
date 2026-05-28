// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library XLayerV4Addresses {
    uint256 internal constant MAINNET_CHAIN_ID = 196;
    uint256 internal constant TESTNET_CHAIN_ID = 1952;
    uint256 internal constant CHAIN_ID = MAINNET_CHAIN_ID;

    address internal constant POOL_MANAGER = 0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32;
    address internal constant POSITION_MANAGER = 0xcF1EAFC6928dC385A342E7C6491d371d2871458b;
    address internal constant STATE_VIEW = 0x76Fd297e2D437cd7f76d50F01AfE6160f86e9990;
    address internal constant UNIVERSAL_ROUTER = 0xDa00aE15d3A71466517129255255db7c0c0956d3;
    address internal constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address internal constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    address internal constant HOOKMATE_DEMO_ROUTER = 0xE4e6CAdE3E2a67F16A5d867C44e1e7Df02f0fc03;
}
