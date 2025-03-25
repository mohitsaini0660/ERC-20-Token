// SPDX-license Identifier: MIT

pragma solidity ^0.8.19;

interface IEquationERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Burn(address indexed from, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Blacklisted(address indexed account, bool isBlacklisted);
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
}
