// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingContract is Ownable, ReentrancyGuard {
    // Cooldown period for unstaking
    uint256 public constant COOLDOWN_PERIOD = 4 hours;
    uint256 public constant UNSTAKE_COOLDOWN = 4 hours;

    // Fee wallet address to collect fees
    address public feeWallet;

    // Fee percentages (as basis points, e.g., 200 = 2%)
    uint256 public depositFeeBps = 200; // 2%
    uint256 public withdrawalFeeBps = 500; // 5%

    struct Pool {
        uint256 apy;                   // Annual Percentage Yield for rewards
        uint256 totalStaked;           // Total amount staked in this pool
        IERC20 stakingToken;           // Staking token for this pool
        IERC20 rewardToken;            // Reward token for this pool
        bool active;                   // Status of the pool (active/inactive)
        mapping(address => uint256) stakedAmounts;  // Staked amount per user
        mapping(address => uint256) lastStakedTime; // Last time the user staked
    }

    // Pool management
    mapping(uint256 => Pool) public pools;  // Mapping pool ID to Pool data
    uint256 public poolCount;               // Number of pools created

    // Events
    event PoolCreated(uint256 indexed poolId, uint256 apy, address stakingToken, address rewardToken);
    event Staked(address indexed user, uint256 poolId, uint256 amount);
    event Unstaked(address indexed user, uint256 poolId, uint256 amount);
    event RewardClaimed(address indexed user, uint256 poolId, uint256 reward);
    event APYAdjusted(uint256 indexed poolId, uint256 newAPY);
    event FeesUpdated(uint256 newDepositFeeBps, uint256 newWithdrawalFeeBps);
    event PoolDeactivated(uint256 indexed poolId);
    event PoolActivated(uint256 indexed poolId);

    modifier feeWalletSet() {
        require(feeWallet != address(0), "Fee wallet not set");
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    modifier poolIsActive(uint256 _poolId) {
        require(pools[_poolId].active, "Pool is not active");
        _;
    }

    // Pass msg.sender to the Ownable constructor to set the initial owner
    constructor() Ownable(msg.sender) {}

    function setFeeWallet(address _feeWallet) external onlyOwner validAddress(_feeWallet) {
        feeWallet = _feeWallet;
    }

    function updateFees(uint256 _depositFeeBps, uint256 _withdrawalFeeBps) external onlyOwner {
        depositFeeBps = _depositFeeBps;
        withdrawalFeeBps = _withdrawalFeeBps;
        emit FeesUpdated(_depositFeeBps, _withdrawalFeeBps);
    }

    function addPool(uint256 _apy, address _stakingToken, address _rewardToken) external onlyOwner validAddress(_stakingToken) validAddress(_rewardToken) {
        Pool storage newPool = pools[poolCount];
        newPool.apy = _apy;
        newPool.stakingToken = IERC20(_stakingToken);
        newPool.rewardToken = IERC20(_rewardToken);
        newPool.active = true;
        poolCount++;
        emit PoolCreated(poolCount - 1, _apy, _stakingToken, _rewardToken);
    }

    function deactivatePool(uint256 _poolId) external onlyOwner {
        require(_poolId < poolCount, "Pool does not exist");
        pools[_poolId].active = false;
        emit PoolDeactivated(_poolId);
    }

    function activatePool(uint256 _poolId) external onlyOwner {
        require(_poolId < poolCount, "Pool does not exist");
        pools[_poolId].active = true;
        emit PoolActivated(_poolId);
    }

    function stake(uint256 _poolId, uint256 _amount) external nonReentrant feeWalletSet poolIsActive(_poolId) {
        require(_amount > 0, "Amount must be greater than zero");

        Pool storage pool = pools[_poolId];
        uint256 fee = (_amount * depositFeeBps) / 10000;
        uint256 amountAfterFee = _amount - fee;

        require(pool.stakingToken.transferFrom(msg.sender, address(this), amountAfterFee), "Transfer failed");
        require(pool.stakingToken.transferFrom(msg.sender, feeWallet, fee), "Fee transfer failed");

        pool.stakedAmounts[msg.sender] += amountAfterFee;
        pool.totalStaked += amountAfterFee;
        pool.lastStakedTime[msg.sender] = block.timestamp;

        adjustAPY(_poolId); // Adjust APY based on the updated total staked amount

        emit Staked(msg.sender, _poolId, amountAfterFee);
    }

    function unstake(uint256 _poolId, uint256 _amount) external nonReentrant feeWalletSet poolIsActive(_poolId) {
        require(_amount > 0, "Amount must be greater than zero");

        Pool storage pool = pools[_poolId];
        uint256 stakedAmount = pool.stakedAmounts[msg.sender];

        require(stakedAmount >= _amount, "Insufficient staked balance");
        require(block.timestamp >= pool.lastStakedTime[msg.sender] + UNSTAKE_COOLDOWN, "Cooldown period not over");

        uint256 fee = (_amount * withdrawalFeeBps) / 10000;
        uint256 amountAfterFee = _amount - fee;

        pool.stakedAmounts[msg.sender] -= _amount;
        pool.totalStaked -= _amount;

        require(pool.stakingToken.transfer(msg.sender, amountAfterFee), "Transfer failed");
        require(pool.stakingToken.transfer(feeWallet, fee), "Fee transfer failed");

        adjustAPY(_poolId); // Adjust APY based on the updated total staked amount

        emit Unstaked(msg.sender, _poolId, amountAfterFee);
    }

    function adjustAPY(uint256 _poolId) internal {
        Pool storage pool = pools[_poolId];
        
        // Dynamic APY adjustment based on TVL thresholds
        if (pool.totalStaked >= 100000 ether) {
            pool.apy = 20; // Reduce to 20% APY for high TVL
        } else if (pool.totalStaked >= 50000 ether) {
            pool.apy = 30; // Medium 30% APY for moderate TVL
        } else {
            pool.apy = 200; // 200% APY initially to attract users
        }

        emit APYAdjusted(_poolId, pool.apy);
    }

    function calculateReward(uint256 _poolId, address _user) public view returns (uint256) {
        Pool storage pool = pools[_poolId];
        uint256 stakedAmount = pool.stakedAmounts[_user];

        if (stakedAmount == 0) {
            return 0;
        }

        uint256 stakingDuration = block.timestamp - pool.lastStakedTime[_user];
        return (stakedAmount * pool.apy * stakingDuration) / (365 days * 100);
    }

    function claimRewards(uint256 _poolId) external nonReentrant poolIsActive(_poolId) {
        Pool storage pool = pools[_poolId];
        uint256 reward = calculateReward(_poolId, msg.sender);
        require(reward > 0, "No rewards available");

        pool.lastStakedTime[msg.sender] = block.timestamp;
        require(pool.rewardToken.transfer(msg.sender, reward), "Reward transfer failed");

        emit RewardClaimed(msg.sender, _poolId, reward);
    }

    function getPoolInfo(uint256 _poolId) external view returns (uint256, address, address, uint256, bool) {
        require(_poolId < poolCount, "Pool does not exist");
        Pool storage pool = pools[_poolId];
        return (pool.apy, address(pool.stakingToken), address(pool.rewardToken), pool.totalStaked, pool.active);
    }

    function getUserStakedAmount(uint256 _poolId, address _user) external view returns (uint256) {
        require(_poolId < poolCount, "Pool does not exist");
        return pools[_poolId].stakedAmounts[_user];
    }

    function getUserLastStakedTime(uint256 _poolId, address _user) external view returns (uint256) {
        require(_poolId < poolCount, "Pool does not exist");
        return pools[_poolId].lastStakedTime[_user];
    }

    function getPoolCount() external view returns (uint256) {
        return poolCount;
    }

    function getCurrentAPY(uint256 _poolId) external view returns (uint256) {
        require(_poolId < poolCount, "Pool does not exist");
        Pool storage pool = pools[_poolId];
        return pool.apy;
    }

    function isPoolActive(uint256 _poolId) external view returns (bool) {
        require(_poolId < poolCount, "Pool does not exist");
        return pools[_poolId].active;
    }
}
