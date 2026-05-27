// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";

import {MockLaunchToken} from "../src/MockLaunchToken.sol";

contract MockLaunchTokenTest is Test {
    address internal constant RECIPIENT = address(0xBEEF);

    function testConstructorMintsInitialSupplyToRecipient() public {
        MockLaunchToken token = new MockLaunchToken("LaunchShield Token", "XSH", RECIPIENT, 1_000_000e18);

        assertEq(token.name(), "LaunchShield Token");
        assertEq(token.symbol(), "XSH");
        assertEq(token.totalSupply(), 1_000_000e18);
        assertEq(token.balanceOf(RECIPIENT), 1_000_000e18);
    }
}
