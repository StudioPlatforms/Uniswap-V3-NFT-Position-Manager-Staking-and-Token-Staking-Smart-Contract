// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface INonfungiblePositionManager {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

contract StakingAndFarming is Ownable, ReentrancyGuard, IERC721Receiver {
    uint256 public constant UNSTAKE_COOLDOWN = 4 hours;

    address public feeWallet;
    uint256 public depositFeeBps = 200; // 2%
    uint256 public withdrawalFeeBps = 500; // 5%
    address public positionManager; // Uniswap V3 NonfungiblePositionManager contract

    struct Pool {
        uint256 apy;
        uint256 totalStaked;
        IERC20 stakingToken;
        IERC721 nftToken;
        IERC20 rewardToken;
        bool supportsNFT;
        bool active;
        uint24 feeTier; // Changed from uint256 to uint24
        address lpPairContract; // LP pair contract address
        mapping(address => uint256) userStakes;
        mapping(address => uint256[]) userNFTs;
        mapping(address => uint256) lastStakeTime;
        uint256 totalRewardsDistributed; // Track total rewards distributed per pool
        uint256[] lpPositions; // Array to store LP token IDs for the pool
    }

    mapping(uint256 => Pool) public pools;
    uint256 public poolCount;
    mapping(uint256 => address[]) private poolUsers; // Mapping to track users per pool
    mapping(uint256 => mapping(address => bool)) private poolUserExists; // Efficient user existence check
    mapping(uint256 => mapping(uint256 => address)) private nftOwner; // Mapping to track NFT owners

    event PoolCreated(
        uint256 poolId,
        uint256 apy,
        address stakingToken,
        address rewardToken,
        bool supportsNFT,
        uint24 feeTier, // Changed from uint256 to uint24
        address lpPairContract
    );
    event Staked(address indexed user, uint256 poolId, uint256 amount, uint256[] nftIds);
    event Unstaked(address indexed user, uint256 poolId, uint256 amount, uint256[] nftIds);
    event RewardClaimed(address indexed user, uint256 poolId, uint256 reward);
    event PoolActivated(uint256 poolId);
    event PoolDeactivated(uint256 poolId);
    event FeesUpdated(uint256 depositFee, uint256 withdrawalFee);
    event RewardsDeposited(uint256 indexed poolId, uint256 amount); // New event for depositRewards
    event MinimumStakeSet(uint256 indexed poolId, uint256 minimumStake); // New event for setMinimumStake

    modifier onlyValidFeeWallet() {
        require(feeWallet != address(0), "Fee wallet not set");
        _;
    }

    modifier onlyActivePool(uint256 poolId) {
        require(poolId < poolCount, "Invalid pool ID");
        require(pools[poolId].active, "Inactive pool");
        _;
    }

    modifier meetsMinimumStake(uint256 poolId, uint256 amount) {
        require(amount >= minimumStake[poolId], "Stake amount too low");
        _;
    }

    constructor(address _feeWallet, address _positionManager, address initialOwner) Ownable(initialOwner) {
        require(_feeWallet != address(0), "Invalid fee wallet");
        require(_positionManager != address(0), "Invalid position manager");
        feeWallet = _feeWallet;
        positionManager = _positionManager;
    }

    function setFeeWallet(address _feeWallet) external onlyOwner {
        require(_feeWallet != address(0), "Invalid fee wallet");
        feeWallet = _feeWallet;
    }

    function updateFees(uint256 _depositFeeBps, uint256 _withdrawalFeeBps) external onlyOwner {
        require(_depositFeeBps <= 1000 && _withdrawalFeeBps <= 1000, "Fees too high");
        depositFeeBps = _depositFeeBps;
        withdrawalFeeBps = _withdrawalFeeBps;
        emit FeesUpdated(_depositFeeBps, _withdrawalFeeBps);
    }

    function createPool(
        uint256 _apy,
        address _stakingToken,
        address _rewardToken,
        address _nftToken,
        bool _supportsNFT,
        uint24 _feeTier,
        address _lpPairContract
    ) external onlyOwner {
        require(_rewardToken != address(0), "Invalid reward token");
        if (!_supportsNFT) require(_stakingToken != address(0), "Invalid staking token");
        if (_supportsNFT) require(_nftToken != address(0), "Invalid NFT token");

        Pool storage pool = pools[poolCount];
        pool.apy = _apy;
        pool.stakingToken = IERC20(_stakingToken);
        pool.rewardToken = IERC20(_rewardToken);
        pool.supportsNFT = _supportsNFT;
        pool.feeTier = _feeTier;
        pool.active = true;
        if (_supportsNFT) pool.nftToken = IERC721(_nftToken);
        pool.lpPairContract = _lpPairContract; // Store LP pair contract address

        emit PoolCreated(poolCount, _apy, _stakingToken, _rewardToken, _supportsNFT, _feeTier, _lpPairContract);
        poolCount++;
    }

    function activatePool(uint256 poolId) external onlyOwner {
        pools[poolId].active = true;
        emit PoolActivated(poolId);
    }

    function deactivatePool(uint256 poolId) external onlyOwner {
        pools[poolId].active = false;
        emit PoolDeactivated(poolId);
    }

    function stake(
        uint256 poolId,
        uint256 amount,
        uint256[] calldata nftIds
    ) external nonReentrant onlyValidFeeWallet onlyActivePool(poolId) meetsMinimumStake(poolId, amount) {
        Pool storage pool = pools[poolId];
        require(amount > 0 || nftIds.length > 0, "Must stake tokens or NFTs");

        if (amount > 0) {
            uint256 fee = (amount * depositFeeBps) / 10000;
            uint256 netAmount = amount - fee;

            require(pool.stakingToken.transferFrom(msg.sender, address(this), netAmount), "Token transfer failed");
            require(pool.stakingToken.transferFrom(msg.sender, feeWallet, fee), "Fee transfer failed");

            pool.userStakes[msg.sender] += netAmount;
            pool.totalStaked += netAmount;
        }

        if (nftIds.length > 0) {
            require(pool.supportsNFT, "NFTs not supported");
            for (uint256 i = 0; i < nftIds.length; i++) {
                INonfungiblePositionManager(positionManager).positions(nftIds[i]);
                pool.nftToken.transferFrom(msg.sender, address(this), nftIds[i]);
                pool.userNFTs[msg.sender].push(nftIds[i]);
                nftOwner[poolId][nftIds[i]] = msg.sender; // Assign NFT owner
            }
        }

        if (!poolUserExists[poolId][msg.sender]) {
            poolUserExists[poolId][msg.sender] = true;
            poolUsers[poolId].push(msg.sender);
        }

        pool.lastStakeTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, poolId, amount, nftIds);
    }

    function unstake(
        uint256 poolId,
        uint256 amount,
        uint256[] calldata nftIds
    ) external nonReentrant onlyValidFeeWallet onlyActivePool(poolId) {
        Pool storage pool = pools[poolId];
        require(amount > 0 || nftIds.length > 0, "Must unstake tokens or NFTs");
        require(block.timestamp >= pool.lastStakeTime[msg.sender] + UNSTAKE_COOLDOWN, "Cooldown active");

        if (amount > 0) {
            require(pool.userStakes[msg.sender] >= amount, "Insufficient tokens");

            uint256 fee = (amount * withdrawalFeeBps) / 10000;
            uint256 netAmount = amount - fee;

            pool.userStakes[msg.sender] -= amount;
            pool.totalStaked -= amount;

            require(pool.stakingToken.transfer(msg.sender, netAmount), "Token transfer failed");
            require(pool.stakingToken.transfer(feeWallet, fee), "Fee transfer failed");
        }

        if (nftIds.length > 0) {
            require(pool.supportsNFT, "NFTs not supported");
            for (uint256 i = 0; i < nftIds.length; i++) {
                uint256 index = findNFTIndex(pool.userNFTs[msg.sender], nftIds[i]);
                require(index < pool.userNFTs[msg.sender].length, "NFT not staked");

                pool.nftToken.transferFrom(address(this), msg.sender, nftIds[i]);
                delete nftOwner[poolId][nftIds[i]]; // Remove NFT owner
                pool.userNFTs[msg.sender][index] = pool.userNFTs[msg.sender][pool.userNFTs[msg.sender].length - 1];
                pool.userNFTs[msg.sender].pop();
            }
        }

        emit Unstaked(msg.sender, poolId, amount, nftIds);
    }

    function claimRewards(uint256 poolId) external nonReentrant onlyActivePool(poolId) {
        Pool storage pool = pools[poolId];
        uint256 reward = calculateReward(poolId, msg.sender);
        require(reward > 0, "No rewards available");

        pool.lastStakeTime[msg.sender] = block.timestamp;
        pool.rewardToken.transfer(msg.sender, reward);
        pool.totalRewardsDistributed += reward; // Track total rewards
        emit RewardClaimed(msg.sender, poolId, reward);
    }

    function calculateReward(uint256 poolId, address user) public view returns (uint256) {
        Pool storage pool = pools[poolId];
        uint256 userStake = pool.userStakes[user];
        if (userStake == 0) return 0;

        uint256 timeStaked = block.timestamp - pool.lastStakeTime[user];

        // Example multiplier logic
        uint256 multiplier;
        if (timeStaked > 90 days) {
            multiplier = 150; // 50% boost
        } else if (timeStaked > 30 days) {
            multiplier = 120; // 20% boost
        } else {
            multiplier = 100;
        }
        return (userStake * pool.apy * timeStaked * multiplier) / (365 days * 10000);
    }

    function findNFTIndex(uint256[] storage nftArray, uint256 nftId) internal view returns (uint256) {
        for (uint256 i = 0; i < nftArray.length; i++) {
            if (nftArray[i] == nftId) {
                return i;
            }
        }
        revert("NFT not found");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // Function to fetch LP pair contract address
    function getLpPairContract(uint256 poolId) public view returns (address) {
        require(poolId < poolCount, "Invalid pool ID");
        return pools[poolId].lpPairContract;
    }

    // Function to fetch total liquidity in the LP pair
    function getTotalLiquidity(uint256 poolId) public view returns (uint128) {
        require(poolId < poolCount, "Invalid pool ID");
        uint128 totalLiquidity = 0;
        uint256[] memory tokenIds = pools[poolId].lpPositions;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            (, , , , , , , uint128 liquidity, , , , ) = INonfungiblePositionManager(positionManager).positions(tokenIds[i]);
            totalLiquidity += liquidity;
        }

        return totalLiquidity;
    }

    // Function to fetch user-specific data
    function getUserInfo(uint256 poolId, address user)
        external
        view
        returns (uint256 userStake, uint256[] memory userNFTs, uint256 lastStakeTime, uint256 pendingRewards)
    {
        Pool storage pool = pools[poolId];
        uint256 rewards = calculateReward(poolId, user);
        return (
            pool.userStakes[user],
            pool.userNFTs[user],
            pool.lastStakeTime[user],
            rewards
        );
    }

    // Function to fetch all active pools
    function getActivePools() external view returns (uint256[] memory) {
        uint256[] memory activePools = new uint256[](poolCount);
        uint256 count = 0;

        for (uint256 i = 0; i < poolCount; i++) {
            if (pools[i].active) {
                activePools[count] = i;
                count++;
            }
        }

        // Resize the array to match the count of active pools
        assembly {
            mstore(activePools, count)
        }

        return activePools;
    }

    // Function to fetch pending rewards for a user
    function getPendingRewards(uint256 poolId, address user) external view returns (uint256) {
        require(poolId < poolCount, "Invalid pool ID");
        return calculateReward(poolId, user);
    }

    // Function to allow emergency withdrawal of staked tokens and NFTs
    function emergencyWithdraw(uint256 poolId) external nonReentrant {
        require(poolId < poolCount, "Invalid pool ID");
        Pool storage pool = pools[poolId];

        uint256 stakedAmount = pool.userStakes[msg.sender];
        require(stakedAmount > 0, "No stake to withdraw");

        pool.userStakes[msg.sender] = 0;
        pool.totalStaked -= stakedAmount;

        require(pool.stakingToken.transfer(msg.sender, stakedAmount), "Withdrawal failed");

        uint256[] memory userNFTs = pool.userNFTs[msg.sender];
        for (uint256 i = 0; i < userNFTs.length; i++) {
            pool.nftToken.transferFrom(address(this), msg.sender, userNFTs[i]);
        }
        delete pool.userNFTs[msg.sender];

        emit Unstaked(msg.sender, poolId, stakedAmount, userNFTs);
    }

    // Function to update certain details of a pool
    function updatePoolDetails(
        uint256 poolId,
        uint256 newApy,
        bool newActiveStatus
    ) external onlyOwner {
        require(poolId < poolCount, "Invalid pool ID");

        Pool storage pool = pools[poolId];
        pool.apy = newApy;
        pool.active = newActiveStatus;
    }

    // Function to set minimum stake requirement for a pool
    mapping(uint256 => uint256) public minimumStake;

    function setMinimumStake(uint256 poolId, uint256 amount) external onlyOwner {
        require(poolId < poolCount, "Invalid pool ID");
        minimumStake[poolId] = amount;
        emit MinimumStakeSet(poolId, amount);
    }

    // Function to deposit additional reward tokens for a specific pool
    function depositRewards(uint256 poolId, uint256 amount) external onlyOwner {
        require(poolId < poolCount, "Invalid pool ID");
        Pool storage pool = pools[poolId];

        require(pool.rewardToken.transferFrom(msg.sender, address(this), amount), "Deposit failed");
        emit RewardsDeposited(poolId, amount);
    }

    // Fallback function to prevent accidental ETH transfers
    fallback() external {
        revert("Direct ETH transfers not allowed");
    }
}
