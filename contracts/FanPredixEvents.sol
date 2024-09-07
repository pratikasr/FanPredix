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
}
