// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Token.sol";

contract TokenTest is Test {
    TaraChatToken token;

    function setUp() public {
        token = new TaraChatToken();

        // Granting permissions explicitly
        token.grantRole(token.RESTRICTED_ROLE(), address(this));
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), 1_000_000_000 * (10 ** 18));
    }

    function testMint() public {
        // The test contract should now have permission to mint
        token.mint(address(1), 500 * 10 ** 18);
        assertEq(token.balanceOf(address(1)), 500 * 10 ** 18);
    }
}
