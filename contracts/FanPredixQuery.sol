// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FanPredixStorage.sol";

abstract contract FanPredixQuery is FanPredixStorage {
    function getMarket(uint256 _marketId) external view returns (Market memory) {
        return markets[_marketId];
    }

    function getOrder(uint256 _orderId) external view returns (Order memory) {
        return orders[_orderId];
    }

    function getBet(uint256 _betId) external view returns (Bet memory) {
        return bets[_betId];
    }

    function getTeam(address _teamManager) external view returns (Team memory) {
        return teams[_teamManager];
    }

    function getUserOrders(address _user) external view returns (Order[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < nextOrderId; i++) {
            if (orders[i].user == _user) {
                count++;
            }
        }

        Order[] memory userOrders = new Order[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < nextOrderId; i++) {
            if (orders[i].user == _user) {
                userOrders[index] = orders[i];
                index++;
            }
        }

        return userOrders;
    }

    function getUserBets(address _user) external view returns (Bet[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < nextBetId; i++) {
            if (bets[i].user == _user) {
                count++;
            }
        }

        Bet[] memory userBets = new Bet[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < nextBetId; i++) {
            if (bets[i].user == _user) {
                userBets[index] = bets[i];
                index++;
            }
        }

        return userBets;
    }

    function getAllMarkets() external view returns (Market[] memory) {
        Market[] memory allMarkets = new Market[](nextMarketId);
        for (uint256 i = 0; i < nextMarketId; i++) {
            allMarkets[i] = markets[i];
        }
        return allMarkets;
    }

    function getAllTeams() external view returns (Team[] memory) {
        uint256 teamCount = 0;
        for (uint256 i = 0; i < nextMarketId; i++) {
            if (teams[address(uint160(i))].teamManager != address(0)) {
                teamCount++;
            }
        }
        Team[] memory allTeams = new Team[](teamCount);
        uint256 index = 0;
        for (uint256 i = 0; i < nextMarketId; i++) {
            if (teams[address(uint160(i))].teamManager != address(0)) {
                allTeams[index] = teams[address(uint160(i))];
                index++;
            }
        }
        return allTeams;
    }

    function getMarketOrders(uint256 _marketId) external view returns (Order[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < nextOrderId; i++) {
            if (orders[i].marketId == _marketId) {
                count++;
            }
        }

        Order[] memory marketOrders = new Order[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < nextOrderId; i++) {
            if (orders[i].marketId == _marketId) {
                marketOrders[index] = orders[i];
                index++;
            }
        }

        return marketOrders;
    }
}
