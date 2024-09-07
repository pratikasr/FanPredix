// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FanPredixStorage.sol";
import "./FanPredixEvents.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FanPredixCore is FanPredixStorage, FanPredixEvents, ReentrancyGuard {

    address public treasury;

    constructor(uint256 _platformFeePercentage, uint256 _minBetAmount, address _treasury) 
        FanPredixStorage(_platformFeePercentage, _minBetAmount) 
    {
        require(_treasury != address(0), "Invalid treasury address");
        treasury = _treasury;
    }

    function updateTreasury(address _newTreasury) external onlyRole(ADMIN_ROLE) {
        require(_newTreasury != address(0), "Invalid treasury address");
        treasury = _newTreasury;
        emit TreasuryUpdated(_newTreasury);
    }

    function addTeam(address _teamManager, string memory _name, address _fanToken) external onlyRole(ADMIN_ROLE) {
        require(!hasRole(TEAM_ROLE, _teamManager), "Team already exists");
        _setupRole(TEAM_ROLE, _teamManager);
        teams[_teamManager] = Team(_name, _teamManager, _fanToken, true);
        emit TeamAdded(_teamManager, _name, _fanToken);
    }

    function revokeTeamRole(address _teamManager) external onlyRole(ADMIN_ROLE) {
        require(hasRole(TEAM_ROLE, _teamManager), "Not a team manager");
        _revokeRole(TEAM_ROLE, _teamManager);
        delete teams[_teamManager];
        emit TeamRoleRevoked(_teamManager);
    }

    function updateTeam(string memory _name, address _fanToken, bool _isActive) external onlyRole(TEAM_ROLE) {
        require(teams[msg.sender].teamManager == msg.sender, "Not team manager");
        teams[msg.sender].name = _name;
        teams[msg.sender].fanToken = _fanToken;
        teams[msg.sender].isActive = _isActive;
        emit TeamUpdated(msg.sender, _name, _fanToken, _isActive);
    }

    function updatePlatformFee(uint256 _newFeePercentage) external onlyRole(ADMIN_ROLE) {
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    function updateMinBetAmount(uint256 _newMinBetAmount) external onlyRole(ADMIN_ROLE) {
        minBetAmount = _newMinBetAmount;
        emit MinBetAmountUpdated(_newMinBetAmount);
    }

    function withdrawFees(address _token) external onlyRole(ADMIN_ROLE) {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "No fees to withdraw");
        require(IERC20(_token).transfer(treasury, balance), "Fee withdrawal failed");
        emit FeesWithdrawn(_token, balance);
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

        _refundUnmatchedOrders(_marketId);

        emit MarketResolved(_marketId, _resolvedOutcomeIndex);
    }

    function _refundUnmatchedOrders(uint256 _marketId) internal {
        for (uint256 i = 0; i < nextOrderId; i++) {
            Order storage order = orders[i];
            if (order.marketId == _marketId && !order.isMatched && order.amount > 0) {
                IERC20(markets[_marketId].fanToken).transfer(order.user, order.amount);
                emit OrderRefunded(order.id, order.amount);
                order.amount = 0;
            }
        }
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
                
                bool isMatched = false;
                if (newOrder.orderType == OrderType.Back) {
                    isMatched = newOrder.odds >= existingOrder.odds;
                } else {
                    isMatched = newOrder.odds <= existingOrder.odds;
                }
                
                if (isMatched) {
                    uint256 matchedAmount = (newOrder.amount < existingOrder.amount) ? newOrder.amount : existingOrder.amount;
                    
                    newOrder.amount -= matchedAmount;
                    existingOrder.amount -= matchedAmount;
                    
                    newOrder.isMatched = (newOrder.amount == 0);
                    existingOrder.isMatched = (existingOrder.amount == 0);
                    
                    // Create bets for both backer and layer
                    _createMatchedBets(newOrder, existingOrder, matchedAmount, market.id);
                    
                    emit OrdersMatched(_orderId, existingOrder.id, matchedAmount);
                    
                    if (newOrder.amount == 0) {
                        break;
                    }
                }
            }
        }
    }

    function _createMatchedBets(Order storage _order1, Order storage _order2, uint256 _matchedAmount, uint256 _marketId) internal {
        uint256 betId1 = nextBetId++;
        uint256 betId2 = nextBetId++;

        Order storage backOrder = _order1.orderType == OrderType.Back ? _order1 : _order2;
        Order storage layOrder = _order1.orderType == OrderType.Lay ? _order1 : _order2;

        // Use the less favorable odds for the matched bet
        uint256 matchedOdds = backOrder.odds < layOrder.odds ? backOrder.odds : layOrder.odds;

        bets[betId1] = Bet({
            id: betId1,
            marketId: _marketId,
            user: backOrder.user,
            outcomeIndex: backOrder.outcomeIndex,
            amount: _matchedAmount,
            odds: matchedOdds,
            orderType: OrderType.Back
        });

        bets[betId2] = Bet({
            id: betId2,
            marketId: _marketId,
            user: layOrder.user,
            outcomeIndex: layOrder.outcomeIndex,
            amount: _matchedAmount,
            odds: matchedOdds,
            orderType: OrderType.Lay
        });

        emit BetCreated(betId1, _marketId, backOrder.user, _matchedAmount, matchedOdds, OrderType.Back);
        emit BetCreated(betId2, _marketId, layOrder.user, _matchedAmount, matchedOdds, OrderType.Lay);
    }

    function _calculateWinnings(address _user, uint256 _marketId) internal view returns (uint256) {
        Market storage market = markets[_marketId];
        uint256 totalWinnings = 0;

        for (uint256 i = 0; i < nextBetId; i++) {
            Bet storage bet = bets[i];
            if (bet.marketId == _marketId && bet.user == _user) {
                if (bet.orderType == OrderType.Back && bet.outcomeIndex == market.resolvedOutcomeIndex) {
                    totalWinnings += bet.amount + (bet.amount * (bet.odds - 1000) / 1000);
                } else if (bet.orderType == OrderType.Lay && bet.outcomeIndex != market.resolvedOutcomeIndex) {
                    totalWinnings += bet.amount;
                }
            }
        }

        return totalWinnings;
    }
}