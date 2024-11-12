Staking Contract
This smart contract enables users to stake tokens, such as LP tokens, to earn rewards in a configurable reward token (e.g., SHINOBI). It includes automatic APY adjustments based on total staked value (TVL), enforced cooldown periods for staking/unstaking, and customizable fee structures to support sustainable staking.

Key Features
Staking & Rewards: Stake tokens in specific pools to earn rewards in a configurable reward token. Supports multiple pools with individual staking and reward tokens.
Cooldown Period: A 4-hour cooldown period is applied for unstaking, preventing rapid staking/unstaking.
Dynamic APY Adjustment: APY scales based on TVL, starting high to attract users and decreasing as TVL grows:
200% APY: Low TVL
30% APY: Moderate TVL
20% APY: High TVL
Fees: Deposit and withdrawal fees (2% and 5%, respectively) are sent to a designated fee wallet to support the contract's ecosystem.
Core Functions
Owner Controls
setFeeWallet(address _feeWallet): Sets the wallet for collecting deposit and withdrawal fees.
updateFees(uint256 _depositFeeBps, uint256 _withdrawalFeeBps): Updates fees in basis points (e.g., 200 = 2%).
addPool(uint256 _apy, address _stakingToken, address _rewardToken): Creates a new staking pool with specified APY, staking token, and reward token.
Staking Functions
stake(uint256 _poolId, uint256 _amount): Stake tokens in a pool with a 2% deposit fee. Remaining tokens are staked.
unstake(uint256 _poolId, uint256 _amount): Unstake tokens from a pool after the cooldown period, with a 5% withdrawal fee.
claimRewards(uint256 _poolId): Claim rewards based on the user’s staked amount, APY, and staking duration.
Information & Utility
getCurrentAPY(uint256 _poolId): Retrieves the current APY for a specified pool.
calculateReward(uint256 _poolId, address _user): Calculates a user’s reward for a given pool.
getPoolInfo(uint256 _poolId): Returns key details for a specific pool.
getUserStakedAmount(uint256 _poolId, address _user): Returns the user’s staked amount in a pool.
getUserLastStakedTime(uint256 _poolId, address _user): Provides the timestamp of the user’s last stake.
APY Adjustment Logic
The contract automatically adjusts APY based on TVL thresholds:

200% for low TVL (initially)
30% for moderate TVL
20% for high TVL
Example Steps
Deploy Contract: Deploy using a tool like Remix, with the deployer as the owner.
Add Pool: Configure pools with addPool, specifying APY, staking token, and reward token.
Stake Tokens: Users stake tokens using stake and start earning.
Claim Rewards & Unstake: Rewards can be claimed with claimRewards, and users can unstake after the cooldown.
