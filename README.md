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
- Grant and revoke TEAM_ROLE to official team addresses

### Team Manager (TEAM_ROLE)
- Create official prediction markets for their events
- Specify the Fan Token to be used for each market
- Resolve markets by proposing the final outcome

### Users (Fans)
- Place back or lay orders on market outcomes using team-specific Fan Tokens
- Cancel their own unmatched orders
- Redeem winnings after market resolution

## Fan Token Integration

Fan Tokens are at the core of FanPredix's functionality:

1. Market Creation: Team managers specify which Fan Token will be used for their markets.
2. Betting: Users place bets using the specified Fan Token for each market.
3. Winnings: Profits are paid out in Fan Tokens.
4. Future Feature: Governance voting for dispute resolution using Fan Tokens.

## User Flow

1. Connect Wallet: Users connect their wallet containing Fan Tokens to the FanPredix dApp.
2. Browse Markets: View available prediction markets created by official team managers.
3. Place Order: Choose an outcome, specify amount and odds, and place a back or lay order using the required Fan Tokens.
4. Order Matching: Orders are matched peer-to-peer based on compatible odds and amounts.
5. Monitor: Track the progress of the event and the market.
6. Redeem Winnings: If successful, claim winnings after market resolution, minus the platform fee.

## Team Manager Flow for Market Creation

1. Obtain TEAM_ROLE: Team addresses must be granted TEAM_ROLE by the admin.
2. Create Market:
   - Specify the Fan Token to be used
   - Set event details: category, question, description, options
   - Define start and end times
3. Monitor Market: Observe user participation.
4. Resolve Market: After the event concludes, propose the final outcome.

## Technical Implementation

### Smart Contract Structure

The main contract handles all core functionalities:

1. Market Management: Creation and resolution of markets
2. Order Placement and Matching: P2P order matching system
3. Bet Settlement: Calculation and distribution of winnings
4. Fee Collection: Automatic deduction of platform fees from winnings

### Key Functions

- grantTeamRole: Grant TEAM_ROLE to an address (admin only)
- revokeTeamRole: Revoke TEAM_ROLE from an address (admin only)
- createMarket: Create a new prediction market (TEAM_ROLE only)
- placeOrder: Place a back or lay order on a specific outcome
- cancelOrder: Cancel an existing unmatched order
- matchOrders: Internal function to match compatible orders
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