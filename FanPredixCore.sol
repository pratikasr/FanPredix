// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FanPredixStorage.sol";
import "./FanPredixEvents.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FanPredixCore is FanPredixStorage, FanPredixEvents, ReentrancyGuard {
    constructor(uint256 _platformFeePercentage, uint256 _minBetAmount) 
        FanPredixStorage(_platformFeePercentage, _minBetAmount) 
    {}

    function addTeam(address _teamManager, string memory _name, address _fanToken) external onlyRole(ADMIN_ROLE) {
        require(!hasRole(TEAM_ROLE, _teamManager), "Team already exists");
        _setupRole(TEAM_ROLE, _teamManager);
        teams[_teamManager] = Team(_name, _teamManager, _fanToken, true);
        emit TeamAdded(_teamManager, _name, _fanToken);
    }

    function updateTeam(string memory _name, address _fanToken, bool _isActive) external onlyRole(TEAM_ROLE) {
        require(teams[msg.sender].teamManager == msg.sender, "Not team manager");
        teams[msg.sender].name = _name;
        teams[msg.sender].fanToken = _fanToken;
        teams[msg.sender].isActive = _isActive;
        emit TeamUpdated(msg.sender, _name, _fanToken, _isActive);
    }

    function createMarket(
        string memory _category,
        string memory _question,
        string memory _description,
        string[] memory _options,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyRole(TEAM_ROLE) {
        require(teams[msg.sender].isActive, "Team is not active");
        require(_startTime > block.timestamp && _endTime > _startTime, "Invalid time range");

        uint256 marketId = nextMarketId++;
        markets[marketId] = Market({
            id: marketId,
            teamManager: msg.sender,
            fanToken: teams[msg.sender].fanToken,
            category: _category,
            question: _question,
            description: _description,
            options: _options,
            startTime: _startTime,
            endTime: _endTime,
            status: MarketStatus.Open,
            resolvedOutcomeIndex: 0
        });

        emit MarketCreated(marketId, msg.sender, teams[msg.sender].fanToken);
    }

    function placeOrder(
        uint256 _marketId,
        uint256 _outcomeIndex,
        OrderType _orderType,
        uint256 _amount,
        uint256 _odds
    ) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Open, "Market is not open");
        require(block.timestamp >= market.startTime && block.timestamp < market.endTime, "Market is not active");
        require(_amount >= minBetAmount, "Bet amount too low");

        uint256 orderId = nextOrderId++;
        orders[orderId] = Order({
            id: orderId,
            marketId: _marketId,
            user: msg.sender,
            outcomeIndex: _outcomeIndex,
            orderType: _orderType,
            amount: _amount,
            odds: _odds,
            isMatched: false
        });

        IERC20(market.fanToken).transferFrom(msg.sender, address(this), _amount);

        emit OrderPlaced(orderId, _marketId, msg.sender);

        _tryMatchOrder(orderId);
    }

    function cancelOrder(uint256 _orderId) external nonReentrant {
        Order storage order = orders[_orderId];
        require(order.user == msg.sender, "Not order owner");
        require(!order.isMatched, "Order already matched");

        Market storage market = markets[order.marketId];
        require(market.status == MarketStatus.Open, "Market is not open");

        order.isMatched = true;
        IERC20(market.fanToken).transfer(msg.sender, order.amount);

        emit OrderCancelled(_orderId, order.marketId);
    }

    function resolveMarket(uint256 _marketId, uint256 _resolvedOutcomeIndex) external onlyRole(TEAM_ROLE) {
        Market storage market = markets[_marketId];
        require(market.teamManager == msg.sender, "Not market manager");
        require(market.status == MarketStatus.Open, "Market is not open");
        require(block.timestamp > market.endTime, "Market has not ended");

        market.status = MarketStatus.Resolved;
        market.resolvedOutcomeIndex = _resolvedOutcomeIndex;

        emit MarketResolved(_marketId, _resolvedOutcomeIndex);
    }

    function redeemWinnings(uint256 _marketId) external nonReentrant {
        Market storage market = markets[_marketId];
        require(market.status == MarketStatus.Resolved, "Market not resolved");

        uint256 winnings = _calculateWinnings(msg.sender, _marketId);
        require(winnings > 0, "No winnings to redeem");

        uint256 fee = (winnings * platformFeePercentage) / 10000;
        uint256 payout = winnings - fee;

        IERC20(market.fanToken).transfer(msg.sender, payout);

        emit WinningsRedeemed(_marketId, msg.sender, payout);
    }

    function _tryMatchOrder(uint256 _orderId) internal {
        Order storage newOrder = orders[_orderId];
        Market storage market = markets[newOrder.marketId];

        for (uint256 i = 0; i < _orderId; i++) {
            Order storage existingOrder = orders[i];
            if (existingOrder.marketId == newOrder.marketId &&
                existingOrder.outcomeIndex == newOrder.outcomeIndex &&
                existingOrder.orderType != newOrder.orderType &&
                !existingOrder.isMatched) {
                
                if ((newOrder.orderType == OrderType.Back && newOrder.odds >= existingOrder.odds) ||
                    (newOrder.orderType == OrderType.Lay && newOrder.odds <= existingOrder.odds)) {
                    
                    uint256 matchedAmount = (newOrder.amount < existingOrder.amount) ? newOrder.amount : existingOrder.amount;
                    
                    newOrder.amount -= matchedAmount;
                    existingOrder.amount -= matchedAmount;
                    
                    newOrder.isMatched = (newOrder.amount == 0);
                    existingOrder.isMatched = (existingOrder.amount == 0);
                    
                    // Create a new bet
                    uint256 betId = nextBetId++;
                    bets[betId] = Bet({
                        id: betId,
                        marketId: market.id,
                        user: (newOrder.orderType == OrderType.Back) ? newOrder.user : existingOrder.user,
                        outcomeIndex: newOrder.outcomeIndex,
                        amount: matchedAmount,
                        odds: existingOrder.odds
                    });
                    
                    if (newOrder.amount == 0) {
                        break;
                    }
                }
            }
        }
    }

    function _calculateWinnings(address _user, uint256 _marketId) internal view returns (uint256) {
        Market storage market = markets[_marketId];
        uint256 totalWinnings = 0;

        for (uint256 i = 0; i < nextBetId; i++) {
            Bet storage bet = bets[i];
            if (bet.marketId == _marketId && bet.user == _user) {
                if (bet.outcomeIndex == market.resolvedOutcomeIndex) {
                    totalWinnings += bet.amount + (bet.amount * (bet.odds - 1000) / 1000);
                }
            }
        }

        return totalWinnings;
    }
}