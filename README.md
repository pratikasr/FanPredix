# FanPredix: Fan Token-Powered P2P Sports Prediction Market

## Overview

FanPredix is a decentralized, peer-to-peer prediction market platform designed specifically for sports events, leveraging team-specific Fan Tokens on the Chiliz blockchain. It enables official team managers to create markets for their matches, allowing fans to participate using the team's Fan Tokens. This creates an engaging, team-centric betting experience while providing additional utility for Fan Tokens.

## Key Features

1. Team-specific markets using Fan Tokens
2. Peer-to-peer order matching system
3. Back and lay betting options
4. Risk-free protocol operation
5. Automated fee collection for platform sustainability

## Roles and Responsibilities

### Admin
- Deploy the FanPredix contract
- Manage contract configuration (e.g., platform fees, minimum bet amounts)
- Add official team addresses with TEAM_ROLE

### Team Manager (TEAM_ROLE)
- Create official prediction markets for their events
- Update team information (name, Fan Token address, active status)
- Resolve markets by proposing the final outcome

### Users (Fans)
- Place back or lay orders on market outcomes using team-specific Fan Tokens
- Cancel their own unmatched orders
- Redeem winnings after market resolution

## Fan Token Integration

Fan Tokens are at the core of FanPredix's functionality:

1. Team Registration: Each team is associated with its specific Fan Token.
2. Market Creation: Team managers create markets using their team's Fan Token.
3. Betting: Users place bets using the specified Fan Token for each market.
4. Winnings: Profits are paid out in Fan Tokens.
5. Future Feature: Governance voting for dispute resolution using Fan Tokens.

## User Flow

1. Connect Wallet: Users connect their wallet containing Fan Tokens to the FanPredix dApp.
2. Browse Markets: View available prediction markets created by official team managers.
3. Place Order: Choose an outcome, specify amount and odds, and place a back or lay order using the required Fan Tokens.
4. Order Matching: Orders are matched peer-to-peer based on compatible odds and amounts.
5. Monitor: Track the progress of the event and the market.
6. Redeem Winnings: If successful, claim winnings after market resolution, minus the platform fee.

## Team Manager Flow

1. Team Registration: Admin adds the team manager address with TEAM_ROLE.
2. Update Team Info: Team manager can update team name, Fan Token address, and active status.
3. Create Market:
   - Set event details: category, question, description, options
   - Define start and end times
4. Monitor Market: Observe user participation.
5. Resolve Market: After the event concludes, propose the final outcome.

## Technical Implementation

### Smart Contract Structure

The project is divided into multiple contracts for better organization and maintainability:

1. FanPredixStructs.sol: Contains all structs and enums.
2. FanPredixStorage.sol: Defines state variables, mappings, and roles.
3. FanPredixEvents.sol: Declares all events used in the project.
4. FanPredixCore.sol: Implements main functionality (team management, market creation, order placement, etc.).
5. FanPredixHelper.sol: Contains helper functions.
6. FanPredixQuery.sol: Implements view functions for querying data.
7. FanPredix.sol: The main contract that inherits from all others.

### Key Functions

- addTeam: Add a new team with TEAM_ROLE (admin only)
- updateTeam: Update team information (team manager only)
- createMarket: Create a new prediction market (TEAM_ROLE only)
- placeOrder: Place a back or lay order on a specific outcome
- cancelOrder: Cancel an existing unmatched order
- _tryMatchOrder: Internal function to match compatible orders
- resolveMarket: Propose the final outcome of a market (TEAM_ROLE only)
- redeemWinnings: Claim winnings for successful bets

## Fund Flow

1. Order Placement: When a user places an order, the required Fan Tokens are transferred to the contract.
2. Order Matching: Upon successful matching, the contract holds the Fan Tokens from both parties.
3. Market Resolution: After the market is resolved by the team manager, winners can claim their winnings.
4. Platform Fee: A configurable percentage of each winning bet is deducted as a platform fee before payout.
5. Refunds: Unmatched orders are automatically refunded when the market is resolved.

## Platform Profitability

FanPredix ensures sustainable operations through an automated fee collection mechanism:

- A small, configurable percentage fee is deducted from winning bets.
- Fees are collected at the time of winning redemption, ensuring the protocol never holds liability.
- Collected fees are sent to a designated treasury address for platform maintenance and development.

## Security Considerations

- Role-based access control (RBAC) for admin and team manager functions
- Time-based checks to prevent actions on expired or invalid markets
- Careful handling of Fan Token transfers and storage
- No protocol liability, as all bets are peer-to-peer and fees are collected from winnings

## Future Enhancements

- Implementation of a governance voting system for dispute resolution using Fan Tokens
- Integration with Chiliz blockchain for real-time sports data feeds
- Enhanced analytics and reporting for users and team managers
- Multi-language support for global accessibility

## Conclusion

FanPredix revolutionizes sports betting by creating a direct connection between teams and their fans through Fan Tokens. By providing a peer-to-peer prediction market platform, it significantly enhances the utility of Fan Tokens and offers an immersive, engaging experience for sports enthusiasts. The platform's design ensures fair, transparent, and sustainable operations, benefiting teams, fans, and the broader sports ecosystem.

