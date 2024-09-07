// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FanPredixStructs.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FanPredixStorage is FanPredixStructs, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    uint256 public platformFeePercentage;
    uint256 public minBetAmount;

    mapping(uint256 => Market) public markets;
    mapping(uint256 => Order) public orders;
    mapping(uint256 => Bet) public bets;
    mapping(address => Team) public teams;

    uint256 public nextMarketId;
    uint256 public nextOrderId;
    uint256 public nextBetId;

    constructor(uint256 _platformFeePercentage, uint256 _minBetAmount) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        platformFeePercentage = _platformFeePercentage;
        minBetAmount = _minBetAmount;
    }
}
