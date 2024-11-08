# Shinobi Staking Contract on Shido Blockchain

This repository contains the **Staking Smart Contract** developed by **3D Studio Europe** for **Shinobi** on the **Shido Blockchain**. The contract allows users to stake tokens, earn rewards, and unstake according to specific conditions. It is designed for flexibility and security, providing a robust staking solution that meets Shinobi’s ecosystem needs.

## Key Features

- **Multiple Staking Pools**: Each pool can have a unique APY and reward token.
- **Secure Mechanisms**: Includes cooldown periods, reentrancy protections, and structured fees.
- **Optimized for Shido Blockchain**: Built for compatibility with Shido’s EVM environment.

## Usage

### Owner Functions
- **`setFeeWallet(address _feeWallet)`**: Sets the wallet to collect fees.
- **`addPool(uint256 _apy, address _rewardToken)`**: Adds a new staking pool with specified APY and reward token.
- **`adjustAPY(uint256 _poolId)`**: Adjusts the APY of a specific pool based on total staked amount.

### User Functions
- **`stake(uint256 _poolId, uint256 _amount)`**: Stake tokens in a specified pool.
- **`claimRewards(uint256 _poolId)`**: Claim rewards from staking.
- **`unstake(uint256 _poolId, uint256 _amount)`**: Unstake tokens after the cooldown period.

## Support

For questions or support, contact **3D Studio Europe**:

- **Email**: [office@3dcity.life](mailto:office@3dcity.life)
- **Telegram**: @official3dcitydev
