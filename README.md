# Staking Contract

This staking smart contract allows users to stake specific tokens (e.g., LP tokens) and earn rewards in SHINOBI or other configurable reward tokens. The contract supports flexible APY adjustments based on total staked value (TVL), automatic cooldown periods, and a fee structure to sustain long-term staking.

## Features

1. **Staking Mechanism**: Users can stake specified tokens to earn rewards in SHINOBI or other configurable reward tokens. The reward token can default to SHINOBI if desired.
2. **Anti-Manipulation Timer**: Enforces a 4-hour cooldown period after staking to prevent frequent staking and unstaking.
3. **Flexible APY**: The contract starts with a high APY to attract users and adjusts the APY automatically based on total staked value (TVL). As TVL grows, APY decreases to more sustainable levels.
4. **Fees Structure**:
   - **Deposit Fee**: 2% fee on staked amounts.
   - **Withdrawal Fee**: 5% fee on unstaked amounts.
   - Fees are directed to a dedicated wallet to support the farm’s operations and development.

## Smart Contract Functions

### Owner-Only Functions

- **`setFeeWallet(address _feeWallet)`**: Set the wallet to collect deposit and withdrawal fees.
- **`updateFees(uint256 _depositFeeBps, uint256 _withdrawalFeeBps)`**: Update the deposit and withdrawal fees in basis points (e.g., 200 = 2%).
- **`addPool(uint256 _apy, address _stakingToken, address _rewardToken)`**: Create a new staking pool with a specified APY, staking token, and reward token. If the reward token is not specified, it defaults to SHINOBI.
- **`updateStakingToken(uint256 _poolId, address _newStakingToken)`**: Update the staking token for an existing pool.

### Staking Functions

- **`stake(uint256 _poolId, uint256 _amount)`**: Stake tokens in a specified pool. A 2% deposit fee is deducted, and the remaining amount is added to the user’s staked balance.
- **`unstake(uint256 _poolId, uint256 _amount)`**: Unstake tokens from a specified pool after the cooldown period. A 5% withdrawal fee is deducted before returning the tokens to the user.
- **`claimRewards(uint256 _poolId)`**: Claim accumulated rewards based on staked balance, APY, and staking duration. Rewards are paid in the pool’s reward token.

### Utility Functions

- **`getCurrentAPY(uint256 _poolId)`**: Returns the current APY for a specific pool.
- **`calculateReward(uint256 _poolId, address _user)`**: Calculates the current reward for a user in a specific pool.
- **`getPoolInfo(uint256 _poolId)`**: Retrieves information about a pool, including APY, staking token, reward token, and total staked.
- **`getUserStakedAmount(uint256 _poolId, address _user)`**: Returns the amount staked by a user in a specific pool.
- **`getUserLastStakedTime(uint256 _poolId, address _user)`**: Returns the last time a user staked in a specific pool.
- **`getPoolCount()`**: Returns the total number of pools created.

## APY Adjustment Logic

The APY is automatically adjusted based on the total value locked (TVL) in each pool. The adjustment thresholds are:
- **APY of 200%** when TVL is low to attract users.
- **APY of 30%** when TVL is moderate.
- **APY of 20%** when TVL reaches high levels.

These adjustments are triggered automatically within the `stake` and `unstake` functions.

## Example Usage

1. **Deploy the Contract**: Deploy the contract using Remix, Hardhat, or Truffle. The deployer is automatically set as the owner.
2. **Set Up a Pool**: Call `addPool` with the desired APY, staking token (e.g., LP token), and reward token (e.g., SHINOBI).
3. **Stake Tokens**: Users can call `stake` to deposit tokens in the pool and start earning rewards.
4. **Claim Rewards**: After staking, users can accumulate rewards and call `claimRewards` to collect them.
5. **Unstake Tokens**: Users can call `unstake` after the cooldown period to retrieve their staked tokens, minus the withdrawal fee.

## Example of Adding a Pool

To create a pool where users stake an LP token and receive SHINOBI as rewards with an initial APY of 200%, use:

```solidity
addPool(200, lpTokenAddress, shinobiTokenAddress);
