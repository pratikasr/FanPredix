// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FanPredixStructs {
    enum OrderType { Back, Lay }
    enum MarketStatus { Open, Closed, Resolved }

    struct Team {
        string name;
        address teamManager;
        address fanToken;
        bool isActive;
    }

    struct Market {
        uint256 id;
        address teamManager;
        address fanToken;
        string category;
        string question;
        string description;
        string[] options;
        uint256 startTime;
        uint256 endTime;
        MarketStatus status;
        uint256 resolvedOutcomeIndex;
    }

    struct Order {
        uint256 id;
        uint256 marketId;
        address user;
        uint256 outcomeIndex;
        OrderType orderType;
        uint256 amount;
        uint256 odds;
        bool isMatched;
    }

    struct Bet {
        uint256 id;
        uint256 marketId;
        address user;
        uint256 outcomeIndex;
        uint256 amount;
        uint256 odds;
    }
}