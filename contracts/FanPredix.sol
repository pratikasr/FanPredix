// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FanPredixCore.sol";
import "./FanPredixHelper.sol";
import "./FanPredixQuery.sol";

contract FanPredix is FanPredixCore, FanPredixHelper, FanPredixQuery {
    constructor(uint256 _platformFeePercentage, uint256 _minBetAmount)
        FanPredixCore(_platformFeePercentage, _minBetAmount)
    {}

}