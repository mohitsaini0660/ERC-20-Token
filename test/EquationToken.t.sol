//SPDX license identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/EquationToken.sol";

contract EquationTokenTest is Test {
    EquationToken token;
    address owner = address(this);
    address user1 = address(0x123);
    address user2 = address(0x456);
    address treasury = address(0x789);

    function setUp() public {
        token = new EquationToken(treasury);
    }

    function testInitialSupply() public view {
        assertEq(token.totalSupply(), 0);
    }
}
