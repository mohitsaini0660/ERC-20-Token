// SPDX license identifier: MIT

pragma solidity ^0.8.19;

import "./interfaces/IEquationERC20.sol";

contract EquationToken is IEquationERC20 {
    string public constant name = "Equation";
    string public constant symbol = "EQT";
    uint256 public totalSupply; // 1 million tokens
    uint8 public constant decimals = 18;
    uint256 public feePercentage = 2;
    address public treasuryWallet;
    address public owner;
    uint256 public stakingRewardRate = 2;
    uint256 public stakingPeriod = 31536000; // 1 year

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public blacklist;
    mapping(address => Stake) public stakes;

    mapping(address => uint) public nonces;
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline)"
        );

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _treasuryWallet) {
        treasuryWallet = _treasuryWallet;
        owner = msg.sender;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name, string version, unit256 chainId, address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        // Mint initial  supply of 100000 EQT token to the owner
        uint256 initialSupply = 100000 * 10 ** 18;
        _mint(owner, initialSupply);
    }

    function _mint(address to, uint256 amount) public onlyOwner {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Mint(to, amount);
    }

    function _burn(uint256 amount) public onlyOwner {
        require(totalSupply >= amount, "Balance is too low");
        totalSupply -= amount;
        emit Burn(msg.sender, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) public {
        allowance[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "Balance is not sufficient");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(owner, spender, value);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(!blacklist[msg.sender] && !blacklist[to], "Blacklisted");

        uint256 taxAmount = (amount * feePercentage) / 100;
        uint256 netAmount = amount - taxAmount;

        _transfer(msg.sender, to, netAmount);
        _transfer(msg.sender, treasuryWallet, taxAmount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        if (allowance[from][msg.sender] >= amount) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - amount;
        }
        _transfer(from, to, amount);
        return true;
    }

    function setBlacklist(address account, bool value) external onlyOwner {
        blacklist[account] = value;
        emit Blacklisted(account, value);
    }

    function setTaxPercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= 10, "Tax is high");
        feePercentage = _feePercentage;
    }

    function stake(uint256 amount) external {
        require(amount >= 0, "Amount must be greater than 0");
        require(balanceOf[msg.sender] >= amount, "Balance is not sufficient");

        _transfer(msg.sender, address(this), amount);
        stakes[msg.sender] = Stake(amount, block.timestamp);
        emit Staked(msg.sender, amount);
    }

    function unstake() external {
        Stake memory userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No Stake found");

        uint256 reward = calculatingReward(msg.sender);
        require(balanceOf[treasuryWallet] >= reward, "Treasury balance is low");

        _transfer(address(this), msg.sender, userStake.amount);

        _transfer(treasuryWallet, msg.sender, reward);

        delete stakes[msg.sender];
        emit Unstaked(msg.sender, userStake.amount);
    }

    function calculatingReward(address staker) public view returns (uint256) {
        Stake memory userStake = stakes[staker];
        require(userStake.amount > 0, "No Stake found");

        uint256 timePassed = block.timestamp - userStake.startTime;
        uint256 annualReward = (userStake.amount * stakingRewardRate) / 100;
        uint256 reward = (annualReward * timePassed) / stakingPeriod;

        return reward;
    }

    function permit(
        address _owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Permit expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveryAddress = ecrecover(digest, v, r, s);
        require(
            recoveryAddress != address(0) && recoveryAddress == owner,
            "Invalid signature"
        );
        _approve(_owner, spender, value);
    }
}
