# Decentralized Stablecoin Protocol

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Installation & Deployment](#installation--deployment)
- [Testing](#testing)
- [Error Handling](#error-handling)
- [Security Considerations](#security-considerations)
- [Contacts & Resources](#contacts--resources)

---

## Overview

Decentralized Stablecoin is an algorithmic, exogenously collateralized stablecoin backed by assets such as WETH and WBTC. The system is inspired by MakerDAO but intentionally simplified—no governance, no fees, no stability modules.

The protocol’s core goal is to maintain a stable $1 peg for the DSC token, backed by user-deposited collateral. The **DSCEngine** contract manages collateral deposits, stablecoin minting and burning, liquidation, and overall accounting.

---

## Architecture

- **DecentralizedStableCoin.sol**  
  ERC20 token with minting and burning controlled exclusively by the DSCEngine contract.

- **DSCEngine.sol**  
  Core protocol logic managing collateral, stablecoin issuance/redemption, liquidation, and health factor monitoring.

- **OracleLib.sol**  
  Library ensuring Chainlink price feed data is up-to-date (no older than 3 hours).

- **HelperConfig.s.sol**  
  Network configuration helper that switches between local Anvil mocks and live Sepolia settings.

- **DeployDSC.s.sol**  
  Deployment script for Foundry that deploys the stablecoin, engine, and configures ownership.

---

## Features

- Multi-collateral support (WETH, WBTC, etc.)
- Minting and burning of DSC strictly controlled by the engine contract.
- Health Factor mechanism to ensure safe collateralization levels.
- Liquidation process with liquidation bonuses for liquidators.
- Real-time price validation via Chainlink oracles with stale data protection.

---

## Installation & Deployment

### Prerequisites

- [Foundry](https://github.com/foundry-rs/foundry) installed
- Solidity 0.8.18 compiler
- `.env` file with the following environment variables (for Sepolia or other network deployments):

```env
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key_here
RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
```

### Install dependencies

```bash
make install
```

### Deploy locally (Anvil)

```bash
forge script script/DeployDSC.s.sol --broadcast --fork-url http://localhost:8545
```

### Deploy on Sepolia testnet

```bash
forge script script/DeployDSC.s.sol --broadcast --rpc-url https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID
```

## Testing

The project contains comprehensive unit tests using Foundry and OpenZeppelin mocks.

### Run tests with:

```bash
make test
```

## Error Handling

The contracts utilize custom errors for gas-efficient and clear revert reasons, for example:

```bash
DSCEngine__NeedsMoreThanZero()

DSCEngine__NotAllowedToken()

OracleLib__StalePrice()

DecentralizedStableCoin__MustBeMoreThanZero()
```

## Security Considerations

- Uses **ReentrancyGuard** to prevent reentrancy attacks.

- Checks ERC20 allowances before transfers.

- Validates input parameters strictly (e.g., no zero addresses, no zero amounts).

- Enforces oracle data freshness before price usage.

- **onlyOwner** modifier limits minting and burning to DSCEngine contract.

## Contacts & Resources

- Author: **WhatFate**

- Source Code: https://github.com/WhatFate/Foundry-DeFi-StableCoin

- Chainlink Documentation: https://docs.chain.link

- Foundry Documentation: https://book.getfoundry.sh/
