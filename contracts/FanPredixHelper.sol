// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FanPredixStorage.sol";

contract FanPredixHelper is FanPredixStorage {
    function calculateFee(uint256 _amount) internal view returns (uint256) {
        return (_amount * platformFeePercentage) / 10000;
    }

    function isMarketOpen(uint256 _marketId) internal view returns (bool) {
        Market storage market = markets[_marketId];
        return (market.status == MarketStatus.Open &&
            block.timestamp >= market.startTime &&
            block.timestamp <= market.endTime);
    }

    function transferFanTokens(address _token, address _from, address _to, uint256 _amount) internal {
        require(IERC20(_token).transferFrom(_from, _to, _amount), "Token transfer failed");
    }
}