# Staking Contract

This smart contract allows users to stake tokens (e.g., LP tokens) and earn rewards in a configurable reward token (e.g., SHINOBI). It includes automatic APY adjustments based on the total staked value (TVL), a cooldown period for unstaking, and a fee structure for sustainability.

## Features

- **Staking & Rewards**: Users can stake tokens in pools to earn rewards. Each pool can have its own staking and reward tokens.
- **Cooldown Period**: Enforces a 4-hour cooldown for unstaking to prevent frequent actions.
- **Dynamic APY**: APY adjusts based on TVL:
  - **200% APY**: Low TVL.
  - **30% APY**: Moderate TVL.
  - **20% APY**: High TVL.
- **Fees**: Includes a 2% deposit fee and 5% withdrawal fee directed to a fee wallet.

## Key Functions

- **Owner Controls**: Set fees, create pools, and activate/deactivate pools.
- **Staking**: Users can stake and unstake tokens with fees applied.
- **Rewards**: Users can claim rewards based on their staked amount and APY.

## Usage

1. **Deploy the Contract**: Deploy using [Remix](https://remix.ethereum.org/) or [Hardhat](https://hardhat.org/).
2. **Set Fee Wallet**: Specify a wallet for collecting fees.
3. **Create Pool**: Use `addPool` to add a staking pool.
4. **Stake & Earn**: Users stake tokens to earn rewards.
5. **Claim Rewards**: Users claim rewards with `claimRewards`.
6. **Unstake**: Users can unstake after the cooldown period.
