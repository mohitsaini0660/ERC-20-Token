// SPDX license identifier: MIT

pragma solidity ^0.8.19;

contract EquationToken {
    string public name = "Equation Token";
    string public symbol = "EQT";
    uint256 public totalSupply; // 1 million tokens
    uint8 public decimals = 18;
    uint256 public feePercentage = 2;
    address public treasuryWallet;
    address public owner;
    uint256 public stakingRewardRate = 10;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public blacklist;
    mapping(address => Stake) public stakes;

    struct Stake {
        uint256 amount;
        uint256 startTime;
    }

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

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _treasuryWallet) {
        treasuryWallet = _treasuryWallet;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(!blacklist[msg.sender] && !blacklist[to], "Blacklisted");

        uint256 taxAmount = (amount * feePercentage) / 100;
        uint256 netAmount = amount - taxAmount;

        _transfer(msg.sender, to, netAmount);
        _transfer(msg.sender, treasuryWallet, taxAmount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(allowance[msg.sender][from] >= amount, "Allowance is exceeded");
        allowance[msg.sender][from] -= amount;
        transfer(to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "Balance is not sufficient");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Mint(to, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        require(totalSupply >= amount, "Balance is too low");
        totalSupply -= amount;
        emit Burn(msg.sender, amount);
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
        uint256 reward = (annualReward * timePassed) / 365;

        return reward;
    }
}
