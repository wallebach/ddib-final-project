# Subscription Platform - Blockchain Final Project

**Team 17** | Deep Dive into Blockchain - Final Project

## Overview

A decentralized subscription platform that enables creators to monetize content through blockchain-based subscriptions. The platform features dual-token economics with STR (utility token) and GRN (governance token).

## Core Features

- **Creator Registration**: Content creators can register and set subscription prices
- **Subscription Management**: Monthly/yearly subscription plans with automatic expiration
- **Dual Token System**:
  - STR: Platform utility token for subscriptions
  - GRN: Governance token with vesting mechanics
- **Revenue Distribution**: Automated fee splitting between creators, DAO treasury, and token accrual
- **Governance**: Platform governance through GRN token voting
- **Multi-Chain Support**: Deployed on Anvil (local), Sepolia, Fuji, and UZH networks

## Smart Contracts

- `SubscriptionPlatform.sol`: Main platform contract
- `STRToken.sol`: ERC20 utility token with minting controls
- `GRNToken.sol`: ERC20 governance token with vesting
- `PlatformGovernance.sol`: Governance contract for platform decisions

## Tech Stack

- **Solidity**: Smart contract development
- **Foundry**: Testing and deployment framework
- **OpenZeppelin**: Security-audited contract libraries
- **Ethers.js**: Frontend blockchain interaction
- **HTML/CSS/JS**: Web interface

## Quick Start

1. Install dependencies:

   ```bash
   forge install
   ```

2. Start local blockchain:

   ```bash
   anvil
   ```

3. Deploy contracts:

   ```bash
   ./deploy.sh
   ```

4. Open `website/index.html` in browser

## Network Deployments

- **Local**: Anvil (chainId: 31337)
- **Testnet**: Sepolia, Fuji
- **Custom**: UZH network

Contract addresses are saved in `contracts.json` after deployment.

## Testing

Run test suite:

```bash
forge test
```

## Media

Demo videos available in `/media/` directory.
