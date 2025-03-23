//SPDX license identifier: MIT

pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/EquationToken.sol";

contract EquationTokenTest is Test {
    EquationToken token;
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);
    address treasury = address(0x3);

    function setUp() public {
        token = new EquationToken(treasury);
    }

    function testMint() public {
        vm.prank(owner);
        token.mint(user1, 200 * 10 ** 18);
        assertEq(token.totalSupply(), 200 * 10 ** 18);
        assertEq(token.balanceOf(user1), 200 * 10 ** 18);
    }

    function testBurn() public {
        vm.prank(owner);
        token.mint(user1, 200 * 10 ** 18);
        token.burn(100 * 10 ** 18);
        assertEq(token.totalSupply(), 100 * 10 ** 18);
    }

    function testTransfer() public {
        vm.prank(owner);
        token.mint(owner, 1000 * 10 ** 18);
        token.transfer(user1, 100 * 10 ** 18);
        assertEq(token.balanceOf(user1), 98 * 10 ** 18);
        assertEq(token.balanceOf(treasury), 2 * 10 ** 18);
    }

    function testSetBlacklist() public {
        vm.prank(owner);
        token.setBlacklist(user1, true);
        assert(token.blacklist(user1));
    }

    function testSetTestPercentage() public {
        vm.prank(owner);
        token.setTaxPercentage(5);
        assert(token.feePercentage() == 5);
    }

    function testStakeAndUnstake() public {
        vm.prank(owner);
        token.mint(owner, 100 * 10 ** 18);
        token.mint(treasury, 10000000 * 10 ** 18);
        token.mint(user1, 5 * 10 ** 18);
        vm.prank(user1);
        token.stake(5 * 10 ** 18);
        assertEq(token.balanceOf(user1), 0);
        assertEq(token.balanceOf(address(token)), 5 * 10 ** 18);

        vm.warp(block.timestamp + 365 days);
        uint256 reward = token.calculatingReward(user1);
        //assertGt(reward, 0);

        vm.prank(user1);
        token.unstake();
        assertEq(token.balanceOf(user1), (5 * 10 ** 18 + reward));
    }
}
