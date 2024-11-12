Staking Contract
This smart contract allows users to stake tokens, such as LP tokens, and earn rewards in a configurable reward token (e.g., SHINOBI). The contract supports flexible APY adjustments based on total staked value (TVL), automatic cooldown periods, and a fee structure to ensure sustainable staking. This project is suitable for decentralized finance (DeFi) applications looking to incentivize staking with dynamically adjusted rewards.

Features
1. Staking & Rewards
Users can stake tokens in specific pools to earn rewards. Each pool can be configured with its own staking and reward tokens. The contract also allows the reward token to default to SHINOBI if desired.

2. Cooldown Period
A 4-hour cooldown period is enforced for unstaking, preventing rapid staking and unstaking to manipulate rewards.

3. Dynamic APY Adjustment
The Annual Percentage Yield (APY) adjusts automatically based on total staked value (TVL):

200% APY: Applied when TVL is low to attract users.
30% APY: Adjusts to this rate as TVL reaches moderate levels.
20% APY: Set when TVL reaches high levels, promoting sustainability.
4. Fee Structure
The contract includes deposit and withdrawal fees directed to a fee wallet to support ongoing operations and development:

Deposit Fee: 2% on each staked amount.
Withdrawal Fee: 5% on each unstaked amount.
Functions Overview
Owner-Only Functions
setFeeWallet(address _feeWallet): Sets the wallet for fee collection.
updateFees(uint256 _depositFeeBps, uint256 _withdrawalFeeBps): Updates deposit and withdrawal fees in basis points.
addPool(uint256 _apy, address _stakingToken, address _rewardToken): Creates a new staking pool with specified APY, staking token, and reward token.
activatePool(uint256 _poolId) and deactivatePool(uint256 _poolId): Activate or deactivate an existing pool.
Staking and Unstaking
stake(uint256 _poolId, uint256 _amount): Allows users to stake tokens in a specified pool. The 2% deposit fee is deducted, and the remaining amount is added to the user’s staked balance.
unstake(uint256 _poolId, uint256 _amount): Allows users to unstake tokens from a pool after the cooldown period. The 5% withdrawal fee is deducted before returning tokens to the user.
Rewards Management
claimRewards(uint256 _poolId): Allows users to claim accumulated rewards based on their staked amount, the pool’s APY, and staking duration.
calculateReward(uint256 _poolId, address _user): Calculates the current reward for a user in a specified pool.
Utility Functions
getCurrentAPY(uint256 _poolId): Returns the current APY for a specified pool.
getPoolInfo(uint256 _poolId): Retrieves information about a pool, including APY, staking token, reward token, and total staked amount.
getUserStakedAmount(uint256 _poolId, address _user): Returns the user’s staked amount in a specified pool.
getUserLastStakedTime(uint256 _poolId, address _user): Provides the timestamp of the user’s last staking action.
APY Adjustment Logic
The contract dynamically adjusts APY to balance rewards with sustainability based on the total staked value in each pool. These adjustments happen automatically within the staking and unstaking functions and follow these thresholds:

200% for low TVL to attract initial users.
30% for moderate TVL.
20% for high TVL, ensuring long-term sustainability.
Example Usage
Step 1: Deploy the Contract
Deploy the contract using a tool like Remix, Hardhat, or Truffle. The deployer address is automatically assigned as the contract owner.

Step 2: Set Up a Fee Wallet
Use the setFeeWallet function to designate a wallet that will receive deposit and withdrawal fees.

Step 3: Create a Staking Pool
To add a pool where users can stake tokens and earn rewards, call addPool with the desired APY, staking token, and reward token.

Step 4: Stake Tokens
Users can call stake to deposit tokens into the specified pool and begin earning rewards. Note that a 2% deposit fee applies.

Step 5: Claim Rewards
Users can claim rewards by calling claimRewards based on their staked balance and the pool’s APY.

Step 6: Unstake Tokens
After the cooldown period, users can call unstake to retrieve their staked tokens, minus the 5% withdrawal fee.

Example Code Snippet: Adding a Pool
To add a pool with an APY of 200% where users stake an LP token and receive SHINOBI as rewards, call:

solidity
Copy code
addPool(200, lpTokenAddress, shinobiTokenAddress);
Installation and Testing
Prerequisites
Node.js
Yarn or npm
Installation
Clone the repository:
bash
Copy code
git clone https://github.com/yourusername/your-repository.git
cd your-repository
Install dependencies:
bash
Copy code
yarn install
Testing
Run tests to ensure functionality:

bash
Copy code
yarn test
License
This project is licensed under the MIT License.

Contributing
Contributions are welcome! Please open an issue or submit a pull request for feature requests, bug fixes, or other improvements.

