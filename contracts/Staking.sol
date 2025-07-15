// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @title StakingAndFarming - Ultimate Overhaul & Expansion
 * @dev Factory pattern with user-created pools, fixed APY, decimal-safe math, and per-share accounting
 * Implements the complete overhaul specification with security improvements and gas optimizations
 */

// Basic interfaces
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

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

// Basic access control
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Reentrancy guard
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// Pausable functionality
abstract contract Pausable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// Safe ERC20 operations
library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// Address utilities
library Address {
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// Minimal proxy clones
library Clones {
    function clone(address implementation) internal returns (address instance) {
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender));
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }
}

// Individual Pool Contract (deployed as clones)
contract StakingPool is ReentrancyGuard, Pausable, IERC721Receiver {
    using SafeERC20 for IERC20;

    // High precision constants
    uint256 constant RAY = 1e27;                    // High precision for per-share calculations
    uint256 constant YEAR = 365 days;               // Seconds in a year (acceptable drift)
    uint256 constant BP = 10_000;                   // Basis points divider
    uint256 constant UNSTAKE_COOLDOWN = 4 hours;    // Cooldown period
    uint256 constant MAX_LIQUIDITY_PER_NFT = 1e24;  // Cap liquidity to prevent economic attacks

    struct PoolData {
        // Immutable after initialize()
        IERC20 stakeToken;
        IERC20 rewardToken;
        uint8 stakeDec;
        uint8 rewardDec;
        uint256 apyBP;              // e.g. 1200 = 12.00%
        address feeWallet;
        uint256 depositFeeBP;       // 0-1000 (0-10%)
        uint256 withdrawFeeBP;      // 0-1000 (0-10%)
        address poolCreator;        // Who created this pool
        bool supportsNFT;           // Whether this pool supports NFT staking
        IERC721 nftToken;           // NFT token for LP positions
        address positionManager;    // Uniswap V3 position manager

        // State variables
        uint256 accRewardPerShare;  // Accumulated rewards per share (in RAY precision)
        uint256 lastAccrualTs;      // Last time rewards were accrued
        uint256 totalStakeR;        // Total stake converted to reward token units
        uint256 availableRewards;   // Available reward tokens in the pool
        bool initialized;           // Initialization flag
    }

    PoolData public data;
    
    // User mappings
    mapping(address => uint256) public userStake;           // User stake in stake token units
    mapping(address => uint256) public userRewardDebt;      // User reward debt for per-share accounting
    mapping(address => uint256[]) public userNFTs;         // User staked NFTs (enumeration)
    mapping(address => mapping(uint256 => bool)) public userNFTStaked; // O(1) NFT lookup
    mapping(address => mapping(uint256 => uint256)) public userNFTIndex; // NFT to index mapping
    mapping(address => uint256) public lastStakeTime;      // Last stake time for cooldown
    mapping(uint256 => address) public nftOwner;           // NFT ID to owner mapping

    // Events
    event Deposited(address indexed user, uint256 amount, uint256 fee);
    event Withdrawn(address indexed user, uint256 amount, uint256 fee);
    event Harvested(address indexed user, uint256 reward);
    event EmergencyWithdrawn(address indexed user, uint256 amount);
    event RewardsDeposited(address indexed depositor, uint256 amount);
    event NFTStaked(address indexed user, uint256[] nftIds);
    event NFTUnstaked(address indexed user, uint256[] nftIds);

    modifier onlyPoolCreator() {
        require(msg.sender == data.poolCreator, "Not pool creator");
        _;
    }

    modifier onlyInitialized() {
        require(data.initialized, "Pool not initialized");
        _;
    }

    /**
     * @dev Initialize the pool (called by factory)
     */
    function initialize(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _apyBP,
        address _feeWallet,
        uint256 _depositFeeBP,
        uint256 _withdrawFeeBP,
        address _poolCreator,
        bool _supportsNFT,
        IERC721 _nftToken,
        address _positionManager
    ) external {
        require(!data.initialized, "Already initialized");
        require(address(_rewardToken) != address(0), "Invalid reward token");
        require(_feeWallet != address(0), "Invalid fee wallet");
        require(_poolCreator != address(0), "Invalid pool creator");
        require(_apyBP <= 5000, "APY cap 50%"); // Anti-scam protection
        require(_depositFeeBP <= 1000, "Deposit fee too high");
        require(_withdrawFeeBP <= 1000, "Withdrawal fee too high");

        if (!_supportsNFT) {
            require(address(_stakeToken) != address(0), "Invalid stake token");
        } else {
            require(address(_nftToken) != address(0), "Invalid NFT token");
            require(_positionManager != address(0), "Invalid position manager");
        }

        data.stakeToken = _stakeToken;
        data.rewardToken = _rewardToken;
        data.rewardDec = _getDecimals(_rewardToken);
        data.stakeDec = _supportsNFT ? data.rewardDec : _getDecimals(_stakeToken); // Match reward decimals for NFTs
        data.apyBP = _apyBP;
        data.feeWallet = _feeWallet;
        data.depositFeeBP = _depositFeeBP;
        data.withdrawFeeBP = _withdrawFeeBP;
        data.poolCreator = _poolCreator;
        data.supportsNFT = _supportsNFT;
        data.nftToken = _nftToken;
        data.positionManager = _positionManager;
        data.lastAccrualTs = block.timestamp;
        data.initialized = true;
    }

    /**
     * @dev Get token decimals safely
     */
    function _getDecimals(IERC20 token) internal view returns (uint8) {
        try token.decimals() returns (uint8 decimals) {
            return decimals;
        } catch {
            return 18; // Default to 18 decimals
        }
    }

    /**
     * @dev Convert stake token amount to reward token units for calculations
     */
    function _toRewardUnits(uint256 amount) internal view returns (uint256) {
        if (data.stakeDec == data.rewardDec) return amount;
        
        // Prevent overflow: cap decimal difference to prevent 10**(>77) overflow
        uint256 decDiff = data.stakeDec < data.rewardDec 
            ? data.rewardDec - data.stakeDec 
            : data.stakeDec - data.rewardDec;
        require(decDiff <= 18, "Decimal difference too large");
        
        if (data.stakeDec < data.rewardDec) {
            return amount * 10 ** (data.rewardDec - data.stakeDec);
        }
        return amount / 10 ** (data.stakeDec - data.rewardDec);
    }

    /**
     * @dev Accrue rewards based on time elapsed and current APY
     */
    function _accrue() internal {
        if (block.timestamp == data.lastAccrualTs || data.totalStakeR == 0) {
            data.lastAccrualTs = block.timestamp;
            return;
        }

        uint256 dt = block.timestamp - data.lastAccrualTs;
        uint256 yearly = (data.apyBP * 1e18) / BP;  // Scale to 1e18
        uint256 maxReward = (data.totalStakeR * yearly * dt) / YEAR / 1e18;
        
        // Pay out what we can, never revert on empty pot
        uint256 reward = maxReward > data.availableRewards 
            ? data.availableRewards    // pay what we can
            : maxReward;
        
        if (reward > 0) {
            data.availableRewards -= reward;
            data.accRewardPerShare += (reward * RAY) / data.totalStakeR;
        }
        
        data.lastAccrualTs = block.timestamp;
    }

    /**
     * @dev Calculate pending rewards for a user
     */
    function pendingRewards(address user) public view returns (uint256) {
        if (userStake[user] == 0 || data.totalStakeR == 0) return 0;

        uint256 accPerShare = data.accRewardPerShare;
        
        // Calculate what the accPerShare would be after accrual - mirror _accrue() logic
        if (block.timestamp > data.lastAccrualTs && data.totalStakeR > 0) {
            uint256 dt = block.timestamp - data.lastAccrualTs;
            uint256 yearly = (data.apyBP * 1e18) / BP;
            uint256 maxReward = (data.totalStakeR * yearly * dt) / YEAR / 1e18;
            
            // Use same min() logic as _accrue() to match actual reward distribution
            uint256 reward = maxReward > data.availableRewards 
                ? data.availableRewards 
                : maxReward;
            
            if (reward > 0) {
                accPerShare += (reward * RAY) / data.totalStakeR;
            }
        }

        uint256 userStakeR = _toRewardUnits(userStake[user]);
        uint256 totalReward = (userStakeR * accPerShare) / RAY;
        return totalReward > userRewardDebt[user] ? totalReward - userRewardDebt[user] : 0;
    }

    /**
     * @dev Calculate user liquidity from NFT positions
     */
    function calculateUserLiquidity(address user) public view returns (uint256) {
        if (!data.supportsNFT) return 0;
        
        uint256[] memory userNFTsArray = userNFTs[user];
        uint256 totalLiquidity = 0;

        for (uint256 i = 0; i < userNFTsArray.length; i++) {
            try INonfungiblePositionManager(data.positionManager).positions(userNFTsArray[i]) 
                returns (uint96, address, address, address, uint24, int24, int24, uint128 liquidity, uint256, uint256, uint128, uint128) {
                totalLiquidity += liquidity;
            } catch {
                // Skip invalid positions
                continue;
            }
        }

        return totalLiquidity;
    }

    /**
     * @dev Deposit stake tokens or NFTs
     */
    function deposit(uint256 amount, uint256[] calldata nftIds) external nonReentrant whenNotPaused onlyInitialized {
        require(amount > 0 || nftIds.length > 0, "Must stake tokens or NFTs");
        
        _accrue();
        
        // Collect any pending rewards first
        uint256 pending = pendingRewards(msg.sender);
        if (pending > 0) {
            data.rewardToken.safeTransfer(msg.sender, pending);
            emit Harvested(msg.sender, pending);
        }

        if (amount > 0) {
            require(!data.supportsNFT, "Cannot stake tokens in NFT pool");
            
            // Calculate and collect deposit fee - optimized single transfer
            uint256 fee = (amount * data.depositFeeBP) / BP;
            uint256 netAmount = amount - fee;

            // Fee-on-transfer protection: check balance before and after
            uint256 balanceBefore = data.stakeToken.balanceOf(address(this));
            data.stakeToken.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = data.stakeToken.balanceOf(address(this));
            require(balanceAfter - balanceBefore == amount, "Fee-on-transfer tokens not supported");
            
            if (fee > 0) {
                data.stakeToken.safeTransfer(data.feeWallet, fee);
            }

            // Update user and pool state
            uint256 netAmountR = _toRewardUnits(netAmount);
            userStake[msg.sender] += netAmount;
            data.totalStakeR += netAmountR;

            emit Deposited(msg.sender, netAmount, fee);
        }

        if (nftIds.length > 0) {
            require(data.supportsNFT, "NFTs not supported");
            
            uint256 totalLiquidity = 0;
            for (uint256 i = 0; i < nftIds.length; i++) {
                // Verify NFT has valid liquidity and enforce cap to prevent economic attacks
                (, , , , , , , uint128 liquidity, , , , ) = INonfungiblePositionManager(data.positionManager).positions(nftIds[i]);
                require(liquidity > 0, "Invalid liquidity for NFT");
                require(liquidity <= MAX_LIQUIDITY_PER_NFT, "Liquidity exceeds maximum allowed");
                
                data.nftToken.safeTransferFrom(msg.sender, address(this), nftIds[i]);
                
                // O(1) NFT tracking
                userNFTIndex[msg.sender][nftIds[i]] = userNFTs[msg.sender].length;
                userNFTStaked[msg.sender][nftIds[i]] = true;
                userNFTs[msg.sender].push(nftIds[i]);
                nftOwner[nftIds[i]] = msg.sender;
                totalLiquidity += liquidity;
            }

            // Update pool state with liquidity as stake
            userStake[msg.sender] += totalLiquidity;
            uint256 totalLiquidityR = _toRewardUnits(totalLiquidity);
            data.totalStakeR += totalLiquidityR;

            emit NFTStaked(msg.sender, nftIds);
        }

        // Update reward debt
        userRewardDebt[msg.sender] = (_toRewardUnits(userStake[msg.sender]) * data.accRewardPerShare) / RAY;
        lastStakeTime[msg.sender] = block.timestamp;
    }

    /**
     * @dev Withdraw stake tokens or NFTs
     */
    function withdraw(uint256 amount, uint256[] calldata nftIds) external nonReentrant onlyInitialized {
        require(amount > 0 || nftIds.length > 0, "Must unstake tokens or NFTs");
        require(block.timestamp >= lastStakeTime[msg.sender] + UNSTAKE_COOLDOWN, "Cooldown active");
        
        _accrue();
        
        // Collect any pending rewards first
        uint256 pending = pendingRewards(msg.sender);
        if (pending > 0) {
            data.rewardToken.safeTransfer(msg.sender, pending);
            emit Harvested(msg.sender, pending);
        }

        if (amount > 0) {
            require(!data.supportsNFT, "Cannot unstake tokens from NFT pool");
            require(userStake[msg.sender] >= amount, "Insufficient stake");
            
            // Calculate and apply withdrawal fee
            uint256 fee = (amount * data.withdrawFeeBP) / BP;
            uint256 netAmount = amount - fee;

            // Update user and pool state - totalStakeR must decrease by full amount (including fees)
            uint256 amountR = _toRewardUnits(amount);
            userStake[msg.sender] -= amount;
            data.totalStakeR -= amountR;

            // Transfer tokens
            data.stakeToken.safeTransfer(msg.sender, netAmount);
            if (fee > 0) {
                data.stakeToken.safeTransfer(data.feeWallet, fee);
            }

            emit Withdrawn(msg.sender, netAmount, fee);
        }

        if (nftIds.length > 0) {
            require(data.supportsNFT, "NFTs not supported");
            
            uint256 totalLiquidity = 0;
            for (uint256 i = 0; i < nftIds.length; i++) {
                // O(1) check if NFT is staked
                require(userNFTStaked[msg.sender][nftIds[i]], "NFT not staked");

                // Get liquidity before transfer
                (, , , , , , , uint128 liquidity, , , , ) = INonfungiblePositionManager(data.positionManager).positions(nftIds[i]);
                totalLiquidity += liquidity;

                data.nftToken.safeTransferFrom(address(this), msg.sender, nftIds[i]);
                delete nftOwner[nftIds[i]];
                
                // O(1) removal from array using swap-and-pop
                uint256 idx = userNFTIndex[msg.sender][nftIds[i]];
                uint256 lastId = userNFTs[msg.sender][userNFTs[msg.sender].length - 1];
                userNFTs[msg.sender][idx] = lastId;
                userNFTIndex[msg.sender][lastId] = idx;
                userNFTs[msg.sender].pop();
                delete userNFTIndex[msg.sender][nftIds[i]];
                delete userNFTStaked[msg.sender][nftIds[i]];
            }

            // Update pool state
            userStake[msg.sender] -= totalLiquidity;
            uint256 totalLiquidityR = _toRewardUnits(totalLiquidity);
            data.totalStakeR -= totalLiquidityR;

            emit NFTUnstaked(msg.sender, nftIds);
        }

        // Update reward debt
        userRewardDebt[msg.sender] = (_toRewardUnits(userStake[msg.sender]) * data.accRewardPerShare) / RAY;
    }

    /**
     * @dev Harvest rewards without withdrawing stake
     */
    function harvest() external nonReentrant onlyInitialized {
        _accrue();
        
        uint256 pending = pendingRewards(msg.sender);
        require(pending > 0, "No rewards available");

        userRewardDebt[msg.sender] = (_toRewardUnits(userStake[msg.sender]) * data.accRewardPerShare) / RAY;
        data.rewardToken.safeTransfer(msg.sender, pending);

        emit Harvested(msg.sender, pending);
    }

    /**
     * @dev Emergency withdraw without rewards (no fees)
     */
    function emergencyWithdraw() external nonReentrant onlyInitialized {
        uint256 amount = userStake[msg.sender];
        require(amount > 0, "No stake to withdraw");

        if (!data.supportsNFT) {
            // Token withdrawal
            uint256 amountR = _toRewardUnits(amount);
            userStake[msg.sender] = 0;
            userRewardDebt[msg.sender] = 0;
            data.totalStakeR -= amountR;

            data.stakeToken.safeTransfer(msg.sender, amount);
        } else {
            // NFT withdrawal
            uint256[] memory userNFTsArray = userNFTs[msg.sender];
            for (uint256 i = 0; i < userNFTsArray.length; i++) {
                data.nftToken.safeTransferFrom(address(this), msg.sender, userNFTsArray[i]);
                delete nftOwner[userNFTsArray[i]];
            }
            delete userNFTs[msg.sender];
            
            userStake[msg.sender] = 0;
            userRewardDebt[msg.sender] = 0;
            data.totalStakeR -= _toRewardUnits(amount);
        }

        emit EmergencyWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Deposit reward tokens to fund the pool
     */
    function depositRewards(uint256 amount) external nonReentrant onlyInitialized {
        require(amount > 0, "Amount must be > 0");
        
        // Fee-on-transfer protection: check actual received amount
        uint256 balBefore = data.rewardToken.balanceOf(address(this));
        data.rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 received = data.rewardToken.balanceOf(address(this)) - balBefore;
        data.availableRewards += received;

        emit RewardsDeposited(msg.sender, received);
    }


    /**
     * @dev Pause the pool (only pool creator)
     */
    function pause() external onlyPoolCreator {
        _pause();
    }

    /**
     * @dev Unpause the pool (only pool creator)
     */
    function unpause() external onlyPoolCreator {
        _unpause();
    }

    /**
     * @dev Get user info
     */
    function getUserInfo(address user) external view returns (
        uint256 userStakeAmount,
        uint256[] memory userNFTsArray,
        uint256 lastStakeTimeVal,
        uint256 pendingRewardsAmount
    ) {
        return (
            userStake[user],
            userNFTs[user],
            lastStakeTime[user],
            pendingRewards(user)
        );
    }

    /**
     * @dev ERC721 receiver
     */
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev Fallback to prevent ETH transfers
     */
    fallback() external {
        revert("Direct ETH transfers not allowed");
    }
}

// Factory Contract
contract StakingAndFarming is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable poolImplementation;
    uint256 public creationFee;                     // Creation fee in ETH or payToken
    IERC20 public payToken;                         // Fee token (address(0) = ETH)
    address public feeWallet;
    uint256 public defaultDepositFeeBP = 200;       // 2%
    uint256 public defaultWithdrawalFeeBP = 500;    // 5%
    uint256 public saltCounter;                     // Monotonic counter for deterministic salts
    bool public nftPoolsEnabled = false;           // Global NFT pool disable switch

    // Token whitelists
    mapping(address => bool) public allowedStakeTokens;
    mapping(address => bool) public allowedRewardTokens;
    
    // Pool tracking
    address[] public allPools;
    mapping(address => address[]) public userPools;     // User to their created pools
    mapping(address => bool) public isValidPool;

    // Events
    event PoolCreated(
        address indexed creator,
        address indexed pool,
        address stakeToken,
        address rewardToken,
        uint256 apyBP,
        bool supportsNFT
    );
    event CreationFeeUpdated(uint256 newFee, address payToken);
    event TokenWhitelisted(address token, bool isStakeToken, bool allowed);
    event DefaultFeesUpdated(uint256 depositFeeBP, uint256 withdrawalFeeBP);

    constructor(address _feeWallet, address initialOwner) Ownable(initialOwner) {
        require(_feeWallet != address(0), "Invalid fee wallet");
        feeWallet = _feeWallet;
        
        // Deploy implementation contract
        poolImplementation = address(new StakingPool());
        
        // Set initial creation fee (0.1 ETH)
        creationFee = 0.1 ether;
        payToken = IERC20(address(0)); // ETH
    }

    /**
     * @dev Create a new staking pool
     */
    function createPool(
        IERC20 stakeToken,
        IERC20 rewardToken,
        uint256 apyBP,
        bool supportsNFT,
        IERC721 nftToken,
        address positionManager
    ) external payable nonReentrant returns (address pool) {
        require(allowedRewardTokens[address(rewardToken)], "Reward token not allowed");
        if (!supportsNFT) {
            require(allowedStakeTokens[address(stakeToken)], "Stake token not allowed");
        } else {
            require(nftPoolsEnabled, "NFT pools disabled");
            require(address(nftToken) != address(0), "Invalid NFT token");
            require(positionManager != address(0), "Invalid position manager");
        }
        require(apyBP <= 5000, "APY cap 50%");

        _collectCreationFee();

        // Deploy pool clone with deterministic salt - prevent overflow
        require(saltCounter < type(uint256).max, "Salt counter overflow");
        bytes32 salt = keccak256(abi.encode(msg.sender, ++saltCounter));
        pool = Clones.cloneDeterministic(poolImplementation, salt);
        
        // Initialize pool
        StakingPool(pool).initialize(
            stakeToken,
            rewardToken,
            apyBP,
            feeWallet,
            defaultDepositFeeBP,
            defaultWithdrawalFeeBP,
            msg.sender,
            supportsNFT,
            nftToken,
            positionManager
        );

        // Track pool
        allPools.push(pool);
        userPools[msg.sender].push(pool);
        isValidPool[pool] = true;

        emit PoolCreated(msg.sender, pool, address(stakeToken), address(rewardToken), apyBP, supportsNFT);
    }

    /**
     * @dev Collect creation fee
     */
    function _collectCreationFee() internal {
        if (address(payToken) == address(0)) {
            require(msg.value == creationFee, "Wrong ETH fee");
            (bool success,) = feeWallet.call{value: msg.value}("");
            require(success, "ETH fee transfer failed");
        } else {
            require(msg.value == 0, "Send ERC-20 fee, not ETH");
            payToken.safeTransferFrom(msg.sender, feeWallet, creationFee);
        }
    }

    /**
     * @dev Update creation fee
     */
    function updateCreationFee(uint256 _creationFee, IERC20 _payToken) external onlyOwner {
        creationFee = _creationFee;
        payToken = _payToken;
        emit CreationFeeUpdated(_creationFee, address(_payToken));
    }

    /**
     * @dev Update default fees
     */
    function updateDefaultFees(uint256 _depositFeeBP, uint256 _withdrawalFeeBP) external onlyOwner {
        require(_depositFeeBP <= 1000 && _withdrawalFeeBP <= 1000, "Fees too high");
        defaultDepositFeeBP = _depositFeeBP;
        defaultWithdrawalFeeBP = _withdrawalFeeBP;
        emit DefaultFeesUpdated(_depositFeeBP, _withdrawalFeeBP);
    }

    /**
     * @dev Whitelist tokens
     */
    function whitelistToken(address token, bool isStakeToken, bool allowed) external onlyOwner {
        if (isStakeToken) {
            allowedStakeTokens[token] = allowed;
        } else {
            allowedRewardTokens[token] = allowed;
        }
        emit TokenWhitelisted(token, isStakeToken, allowed);
    }

    /**
     * @dev Update fee wallet
     */
    function updateFeeWallet(address _feeWallet) external onlyOwner {
        require(_feeWallet != address(0), "Invalid fee wallet");
        feeWallet = _feeWallet;
    }

    /**
     * @dev Enable or disable NFT pool creation
     */
    function setNFTPoolsEnabled(bool _enabled) external onlyOwner {
        nftPoolsEnabled = _enabled;
    }

    /**
     * @dev Get all pools
     */
    function getAllPools() external view returns (address[] memory) {
        return allPools;
    }

    /**
     * @dev Get user pools
     */
    function getUserPools(address user) external view returns (address[] memory) {
        return userPools[user];
    }

    /**
     * @dev Get pool count
     */
    function getPoolCount() external view returns (uint256) {
        return allPools.length;
    }

    /**
     * @dev Fallback to prevent ETH transfers
     */
    fallback() external {
        revert("Direct ETH transfers not allowed");
    }

    /**
     * @dev Receive function to accept ETH for creation fees
     */
    receive() external payable {
        revert("Use createPool function");
    }
}
