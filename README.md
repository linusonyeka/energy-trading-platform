# Decentralized Energy Trading Platform

A blockchain-based platform enabling peer-to-peer energy trading between producers and consumers using Clarity smart contracts on the Stacks blockchain.

## Overview

This project implements a decentralized marketplace for renewable energy trading, allowing:

- Energy producers to register and list their excess energy for sale
- Energy consumers to purchase directly from producers
- Transparent and immutable record of all energy transactions
- Reputation system for producers based on successful transactions
- Tiered benefits for regular consumers

## Features

### For Energy Producers

- Register as an energy producer on the platform
- Add generated energy to your available balance
- Create and manage energy sale offers with customizable:
  - Energy amount
  - Price per unit
  - Expiration time
  - Energy type (solar, wind, hydro, etc.)
  - Carbon offset certification
- Track energy sales, earnings, and reputation score

### For Energy Consumers

- Register as an energy consumer on the platform
- Browse available energy offers
- Purchase energy directly from producers with transparent pricing
- Earn consumer tier benefits based on purchase volume
- View complete purchase history and energy usage

### Platform Functions

- Secure peer-to-peer energy trading with automated settlement
- Minimal platform fees (default 1%)
- Transparent transaction records on the blockchain
- Reputation system to promote reliable producers
- Consumer tier system to reward loyal customers

## Technical Implementation

The platform is built using Clarity, a decidable smart contract language designed for the Stacks blockchain. Key technical components include:

- Data maps for producer profiles, consumer profiles, and energy offers
- Transaction processing logic with fee calculation
- Reputation scoring system
- Energy offer lifecycle management
- Administrative controls for platform management

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development, testing, and deployment tool
- [Stacks Wallet](https://www.hiro.so/wallet) - For interacting with the deployed contract

### Setup and Deployment

1. Clone this repository
   ```
   git clone https://github.com/yourusername/decentralized-energy-trading.git
   cd decentralized-energy-trading
   ```

2. Install dependencies
   ```
   npm install
   ```

3. Test the contract locally
   ```
   clarinet test
   ```

4. Deploy to testnet
   ```
   clarinet deploy --testnet
   ```

## Usage Guide

### For Producers

1. Register as a producer using `register-producer`
2. Add your generated energy using `add-generated-energy`
3. Create energy offers with `create-energy-offer`
4. Monitor your sales and reputation

### For Consumers

1. Register as a consumer using `register-consumer`
2. Find available energy offers
3. Purchase energy with `purchase-energy`
4. Track your energy purchases and tier status

## Security

This contract includes security measures such as:

- Access control for administrative functions
- Input validation for all operations
- Prevention of self-trading
- Checks for sufficient energy units and balances

## Future Enhancements

- Integration with real-world energy monitoring devices
- Support for energy futures contracts
- Carbon credit trading
- Community governance mechanisms
- Advanced reputation algorithms
- Multi-token payment options

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request