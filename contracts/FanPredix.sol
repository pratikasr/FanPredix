// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FanPredixCore.sol";
import "./FanPredixHelper.sol";
import "./FanPredixQuery.sol";

contract FanPredix is FanPredixCore, FanPredixHelper, FanPredixQuery {
    constructor(uint256 _platformFeePercentage, uint256 _minBetAmount, address _treasury)
        FanPredixCore(_platformFeePercentage, _minBetAmount, _treasury)
    {}

    function transferFanTokens(address _token, address _from, address _to, uint256 _amount) internal override {
        super.transferFanTokens(_token, _from, _to, _amount);
    }
}