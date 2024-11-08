# Shinobi Staking Contract on Shido Blockchain

This repository contains the **Staking Smart Contract** developed by **3D Studio Europe** for **Shinobi** on the **Shido Blockchain**. This contract allows users to stake tokens, earn rewards, and unstake with specified conditions. It provides a flexible and secure staking mechanism tailored to Shinobi’s needs on the Shido Blockchain.

---

## 📑 Table of Contents
- [About the Project](#about-the-project)
- [Features](#features)
- [Getting Started](#getting-started)
- [Smart Contract Overview](#smart-contract-overview)
- [Usage Instructions](#usage-instructions)
  - [Owner Functions](#owner-functions)
  - [User Functions](#user-functions)
- [Support and Contact](#support-and-contact)

---

## 📝 About the Project

This contract was developed as part of a partnership between **3D Studio Europe** and **Shinobi** to provide a robust staking solution on the Shido Blockchain. This staking contract allows Shinobi's community to participate in staking activities, where they can earn rewards and contribute to the ecosystem's growth.

## ✨ Features

- **Multi-Pool Staking**: Supports multiple staking pools, each with unique reward tokens and APY (Annual Percentage Yield).
- **Secure Staking Mechanism**: Includes cooldown periods, reentrancy protections, and a structured fee mechanism.
- **Configurable Reward System**: Enables flexible reward distribution based on APY and Total Value Locked (TVL) in each pool.
- **Compatibility with Shido Blockchain**: Tailored to work seamlessly on the Shido Blockchain, which is EVM-compatible.

---

## 🚀 Getting Started

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/YourUsername/Shinobi-Staking-Contract.git
   cd Shinobi-Staking-Contract
Install Dependencies (if using a local development environment like Hardhat):

bash
Copy code
npm install
Compile the Contract:

Remix: Open the contract file in Remix and compile.
Hardhat:
bash
Copy code
npx hardhat compile
Deploy the Contract:

Follow the instructions to deploy the contract on the Shido network, or refer to the documentation in this repository for further deployment steps.
📜 Smart Contract Overview
The Staking Contract enables staking and reward distribution for Shinobi’s ecosystem. It includes:

Owner Functions: Functions to manage pools, set fees, and configure the staking environment.
User Functions: Functions allowing users to stake, claim rewards, and unstake their tokens.
View Functions: Functions that provide information about pools and user stakes.
For detailed interaction instructions, see Usage Instructions.

⚙️ Usage Instructions
🔑 Owner Functions
setFeeWallet(address _feeWallet): Sets the wallet address where fees will be collected.
addPool(uint256 _apy, address _rewardToken): Creates a new staking pool with a specified APY and reward token.
adjustAPY(uint256 _poolId): Adjusts the APY for a specific pool based on TVL.
👤 User Functions
stake(uint256 _poolId, uint256 _amount): Allows users to stake tokens in a specified pool to earn rewards.
claimRewards(uint256 _poolId): Allows users to claim their accumulated rewards from a specific pool.
unstake(uint256 _poolId, uint256 _amount): Allows users to unstake tokens from a pool after the cooldown period.
For full details on each function, please refer to the Interaction Guide.

📞 Support and Contact
For questions, support, or contributions, please reach out to:

3D Studio Europe
Email: office@3dcity.life
Telegram: @official3dcitydev
We appreciate feedback and contributions that enhance the functionality and security of this staking solution.
