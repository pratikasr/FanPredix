// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FanPredixStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract FanPredixHelper is FanPredixStorage {
    function calculateFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * platformFeePercentage) / 10000;
    }

    function isMarketOpen(uint256 _marketId) internal view returns (bool) {
        Market storage market = markets[_marketId];
        return (market.status == MarketStatus.Open &&
            block.timestamp >= market.startTime &&
            block.timestamp <= market.endTime);
    }
}