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
        uint256 apy;                    // APY for rewards
        uint256 totalStaked;            // Total tokens staked
        IERC20 stakingToken;            // Token being staked
        IERC721 nftToken;               // NFT associated with the pool (for farms)
        IERC20 rewardToken;             // Token used for rewards
        bool supportsNFT;               // Whether the pool supports NFT farming
        bool active;                    // Active status
        uint24 feeTier;                 // Uniswap V3 fee tier for NFT verification
        mapping(address => uint256) userStakes; // User's staked tokens
        mapping(address => uint256[]) userNFTs; // User's staked NFTs
        mapping(address => uint256) lastStakeTime; // Last staking time
    }

    mapping(uint256 => Pool) public pools;
    uint256 public poolCount;
    mapping(uint256 => address) public nftOwner; // Tracks NFT owners for farms

    event PoolCreated(
        uint256 poolId,
        uint256 apy,
        address stakingToken,
        address rewardToken,
        bool supportsNFT,
        uint24 feeTier
    );
    event Staked(address indexed user, uint256 poolId, uint256 amount, uint256[] nftIds);
    event Unstaked(address indexed user, uint256 poolId, uint256 amount, uint256[] nftIds);
    event RewardClaimed(address indexed user, uint256 poolId, uint256 reward);
    event PoolActivated(uint256 poolId);
    event PoolDeactivated(uint256 poolId);
    event FeesUpdated(uint256 depositFee, uint256 withdrawalFee);
    event EmergencyWithdraw(address token, uint256 amount);

    modifier onlyValidFeeWallet() {
        require(feeWallet != address(0), "Fee wallet not set");
        _;
    }

    modifier onlyActivePool(uint256 poolId) {
        require(poolId < poolCount, "Invalid pool ID");
        require(pools[poolId].active, "Inactive pool");
        _;
    }

    constructor(address _feeWallet, address _positionManager, address initialOwner) Ownable(initialOwner) {
        require(_feeWallet != address(0), "Invalid fee wallet");
        require(_positionManager != address(0), "Invalid position manager");
        feeWallet = _feeWallet;
        positionManager = _positionManager;
    }

    // Owner-only functions
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
    uint24 _feeTier
) external onlyOwner {
    // Validate reward token
    require(_rewardToken != address(0), "Invalid reward token");

    // Validate staking token only for non-NFT pools
    if (!_supportsNFT) {
        require(_stakingToken != address(0), "Invalid staking token");
    }

    // Validate NFT token only for NFT pools
    if (_supportsNFT) {
        require(_nftToken != address(0), "Invalid NFT token");
    }

    // Initialize the pool
    Pool storage pool = pools[poolCount];
    pool.apy = _apy;
    pool.stakingToken = IERC20(_stakingToken);
    pool.rewardToken = IERC20(_rewardToken);
    pool.supportsNFT = _supportsNFT;
    pool.feeTier = _feeTier;
    pool.active = true;

    if (_supportsNFT) {
        pool.nftToken = IERC721(_nftToken);
    }

    // Emit pool creation event
    emit PoolCreated(poolCount, _apy, _stakingToken, _rewardToken, _supportsNFT, _feeTier);

    // Increment pool count
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

    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
        emit EmergencyWithdraw(token, amount);
    }

    // User functions
    function stake(
        uint256 poolId,
        uint256 amount,
        uint256[] calldata nftIds
    ) external nonReentrant onlyValidFeeWallet onlyActivePool(poolId) {
        Pool storage pool = pools[poolId];
        require(amount > 0 || nftIds.length > 0, "Must stake tokens or NFTs");

        // Handle token staking
        if (amount > 0) {
            uint256 fee = (amount * depositFeeBps) / 10000;
            uint256 netAmount = amount - fee;

            require(pool.stakingToken.transferFrom(msg.sender, address(this), netAmount), "Token transfer failed");
            require(pool.stakingToken.transferFrom(msg.sender, feeWallet, fee), "Fee transfer failed");

            pool.userStakes[msg.sender] += netAmount;
            pool.totalStaked += netAmount;
        }

        // Handle NFT staking
        if (nftIds.length > 0) {
            require(pool.supportsNFT, "NFTs not supported in this pool");

            for (uint256 i = 0; i < nftIds.length; i++) {
                INonfungiblePositionManager(positionManager).positions(nftIds[i]);
                pool.nftToken.transferFrom(msg.sender, address(this), nftIds[i]);
                pool.userNFTs[msg.sender].push(nftIds[i]);
                nftOwner[nftIds[i]] = msg.sender;
            }
        }

        pool.lastStakeTime[msg.sender] = block.timestamp;

        emit Staked(msg.sender, poolId, amount, nftIds);
    }

    // Add additional user and owner functions for unstaking, claiming rewards, etc.

function onERC721Received(
    address /*operator*/,
    address /*from*/,
    uint256 /*tokenId*/,
    bytes calldata /*data*/
) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
}

}
