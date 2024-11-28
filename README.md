# StakingAndFarming Contract

This Solidity smart contract combines **token** and **NFT staking** with farming features. Built on the **Uniswap V3 ecosystem**, it enables flexible staking rewards, dynamic APY adjustment, and comprehensive pool management for both token-based and NFT-based liquidity providers.

## Features
- **Dual Staking Options**: Supports both ERC20 tokens and NFTs as staking assets.
- **Dynamic APY Calculation**: Automatically adjusts APY based on the total staked amount or NFT liquidity.
- **Reward Distribution**: Claims rewards based on staking duration, asset type, and APY.
- **Unstake Cooldown**: Implements a 4-hour cooldown period for unstaking.
- **Fee Management**: Configurable deposit and withdrawal fees, directed to a fee wallet.
- **Emergency Withdrawals**: Allows users to withdraw staked tokens or NFTs during emergencies.
- **Comprehensive Pool Management**:
  - Create, activate, deactivate, and update pools.
  - Customize APY scaling, fee tiers, and liquidity thresholds.
- **Uniswap V3 Integration**:
  - Tracks and validates NFT liquidity via the NonfungiblePositionManager.
  - Includes support for LP pair contracts and fee tiers.
- **Security Enhancements**:
  - Utilizes OpenZeppelin's SafeERC20, ReentrancyGuard, and Ownable contracts.
  - Prevents reentrancy attacks and direct ETH transfers.

## Events
- **`PoolCreated`**: Triggered when a new pool is created.
- **`Staked` / `Unstaked`**: Tracks staking and unstaking of tokens or NFTs.
- **`RewardClaimed`**: Logs reward claims by users.
- **`PoolActivated` / `PoolDeactivated`**: Indicates pool status changes.
- **`FeesUpdated`**: Reflects changes in deposit and withdrawal fees.
- **`RewardsDeposited`**: Logs reward token deposits for specific pools.
- **`RewardCalculated`**: Logs reward calculations for users.

## Usage Scenarios
1. **Staking Pools**: Configure pools for token holders with dynamic APY scaling.
2. **NFT Liquidity Farming**: Leverage Uniswap V3 NFT liquidity for enhanced rewards.
3. **Yield Optimization**: Boost staking rewards for long-term liquidity providers.
4. **DeFi Integrations**: Add customizable farming mechanics to decentralized finance platforms.

## Technology Stack
- **Solidity**: ^0.8.28
- **OpenZeppelin Contracts**
- **Uniswap V3 Integration**

## Getting Started
1. Deploy the contract with the required fee wallet and Uniswap V3 position manager.
2. Configure staking pools with specific parameters such as APY, supported asset type (token or NFT), and fee structure.
3. Stake tokens or NFTs to start earning rewards.

## License
This project is licensed under the **MIT License**.
