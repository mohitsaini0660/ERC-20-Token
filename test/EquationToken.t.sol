// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/EquationERC20.sol";

contract EquationTokenTest is Test {
    EquationToken token;
    address owner = address(0x123);
    address user1 = address(0x456);
    address user2 = address(0x789);
    address treasury = address(0xABC);

    function setUp() public {
        vm.prank(owner);
        token = new EquationToken(treasury);
    }

    function testMint() public {
        vm.prank(owner);
        token._mint(user1, 1000 ether);
        assertEq(token.balanceOf(user1), 1000 ether);
    }

    function testBurn() public {
        vm.prank(owner);
        token._mint(user1, 1000 ether);
        vm.prank(owner);
        token._burn(500 ether);
        assertEq(token.totalSupply(), 500 ether);
    }

    function testTransfer() public {
        vm.prank(owner);
        token._mint(user1, 1000 ether);
        vm.prank(user1);
        token.transfer(user2, 500 ether);
        assertEq(token.balanceOf(user2), 490 ether);
    }

    function testApproveAndTransferFrom() public {
        vm.prank(owner);
        token._mint(user1, 2000 ether); // Mint tokens to user1 // Mint tokens to user2

        vm.prank(user1);
        token.approve(user2, 500 ether); // user1 approves user2 to spend 500 tokens

        vm.prank(user2);
        token.transferFrom(user1, user2, 500 ether); // user2 transfers from user1

        assertEq(token.balanceOf(user2), 500 ether);
        assertEq(token.balanceOf(user1), 1500 ether);
    }

    function testBlacklist() public {
        vm.prank(owner);
        token.setBlacklist(user1, true);
        vm.expectRevert("Blacklisted");
        vm.prank(user1);
        token.transfer(user2, 100 ether);
    }

    function testStake() public {
        vm.prank(owner);
        token._mint(user1, 1000 ether);
        vm.prank(user1);
        token.stake(500 ether);
        (uint256 amount, ) = token.stakes(user1);
        assertEq(amount, 500 ether);
    }

    function testUnstake() public {
        vm.prank(owner);
        token._mint(user1, 1000 ether);
        vm.prank(owner);
        token._mint(treasury, 1000000000 ether);
        vm.prank(user1);
        token.stake(500 ether);
        vm.warp(block.timestamp + 365 days);
        vm.prank(user1);
        token.unstake();
        assertEq(token.balanceOf(user1), 1010 ether);
    }
}
