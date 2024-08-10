// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TokenTest is Test {
    MyToken token;

    function setUp() public {
        token = new MyToken(1000 * 10 ** 18);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1000 * 10 ** 18);
    }

    function testMint() public {
        token.mint(address(1), 500 * 10 ** 18);
        assertEq(token.balanceOf(address(1)), 500 * 10 ** 18);
    }
}
