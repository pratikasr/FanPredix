// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FanPredixStructs.sol";

contract FanPredixEvents is FanPredixStructs {
    event TeamAdded(address indexed teamManager, string name, address fanToken);
    event TeamUpdated(address indexed teamManager, string name, address fanToken, bool isActive);
    event MarketCreated(uint256 indexed marketId, address indexed teamManager, address fanToken);
    event OrderPlaced(uint256 indexed orderId, uint256 indexed marketId, address indexed user);
    event OrderCancelled(uint256 indexed orderId, uint256 indexed marketId);
    event MarketResolved(uint256 indexed marketId, uint256 resolvedOutcomeIndex);
    event WinningsRedeemed(uint256 indexed marketId, address indexed user, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);
    event TreasuryUpdated(address newTreasury);
    event TeamRoleRevoked(address teamManager);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event MinBetAmountUpdated(uint256 newMinBetAmount);
    event FeesWithdrawn(address token, uint256 amount);
    event OrderRefunded(uint256 orderId, uint256 amount);
    event OrdersMatched(uint256 orderId1, uint256 orderId2, uint256 matchedAmount);
    event BetCreated(uint256 betId, uint256 marketId, address user, uint256 amount, uint256 odds, OrderType orderType);
}