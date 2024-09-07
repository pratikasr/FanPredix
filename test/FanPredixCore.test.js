const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FanPredixCore", function () {
  let FanPredixCore, fanPredixCore, owner, admin, teamManager, user1, user2, treasury;
  let MockToken, mockToken;

  const PLATFORM_FEE = 250; // 2.5%
  const MIN_BET_AMOUNT = ethers.utils.parseEther("10");
  const ODDS_BASE = 1000;

  beforeEach(async function () {
    [owner, admin, teamManager, user1, user2, treasury] = await ethers.getSigners();

    // Deploy mock ERC20 token
    MockToken = await ethers.getContractFactory("MockToken");
    mockToken = await MockToken.deploy("Fan Token", "FAN");
    await mockToken.deployed();

    // Deploy FanPredixCore
    FanPredixCore = await ethers.getContractFactory("FanPredixCore");
    fanPredixCore = await FanPredixCore.deploy(PLATFORM_FEE, MIN_BET_AMOUNT, treasury.address);
    await fanPredixCore.deployed();

    // Grant admin role
    await fanPredixCore.grantRole(await fanPredixCore.ADMIN_ROLE(), admin.address);

    // Add team
    await fanPredixCore.connect(admin).addTeam(teamManager.address, "Test Team", mockToken.address);

    // Mint tokens for users
    await mockToken.mint(user1.address, ethers.utils.parseEther("1000"));
    await mockToken.mint(user2.address, ethers.utils.parseEther("1000"));

    // Approve tokens for FanPredixCore
    await mockToken.connect(user1).approve(fanPredixCore.address, ethers.constants.MaxUint256);
    await mockToken.connect(user2).approve(fanPredixCore.address, ethers.constants.MaxUint256);
  });

  it("Should create a market", async function () {
    const startTime = Math.floor(Date.now() / 1000) + 60; // 1 minute from now
    const endTime = startTime + 3600; // 1 hour after start

    await expect(fanPredixCore.connect(teamManager).createMarket(
      "Sports",
      "Who will win?",
      "Team A vs Team B",
      ["Team A", "Team B"],
      startTime,
      endTime
    )).to.emit(fanPredixCore, "MarketCreated");
  });

  it("Should place orders and match them", async function () {
    const startTime = Math.floor(Date.now() / 1000) + 60; // 1 minute from now
    const endTime = startTime + 3600; // 1 hour after start

    await fanPredixCore.connect(teamManager).createMarket(
      "Sports",
      "Who will win?",
      "Team A vs Team B",
      ["Team A", "Team B"],
      startTime,
      endTime
    );

    // Advance time to after market start
    await ethers.provider.send("evm_increaseTime", [61]);
    await ethers.provider.send("evm_mine");

    // Place back order
    await expect(fanPredixCore.connect(user1).placeOrder(
      0, // marketId
      0, // outcomeIndex
      0, // OrderType.Back
      ethers.utils.parseEther("100"),
      1200 // 1.2 odds (1200 / ODDS_BASE)
    )).to.emit(fanPredixCore, "OrderPlaced");

    // Place lay order
    await expect(fanPredixCore.connect(user2).placeOrder(
      0, // marketId
      0, // outcomeIndex
      1, // OrderType.Lay
      ethers.utils.parseEther("100"),
      1200 // 1.2 odds (1200 / ODDS_BASE)
    )).to.emit(fanPredixCore, "OrdersMatched");
  });

  it("Should resolve market and allow winning redemption", async function () {
    const currentTimestamp = (await ethers.provider.getBlock("latest")).timestamp;
    const startTime = currentTimestamp + 60; // 1 minute from now
    const endTime = startTime + 3600; // 1 hour after start

    console.log("Current time:", currentTimestamp);
    console.log("Start time:", startTime);
    console.log("End time:", endTime);

    await fanPredixCore.connect(teamManager).createMarket(
      "Sports",
      "Who will win?",
      "Team A vs Team B",
      ["Team A", "Team B"],
      startTime,
      endTime
    );

    // Advance time to after market start
    await ethers.provider.send("evm_increaseTime", [61]);
    await ethers.provider.send("evm_mine");

    // Place matching orders
    await fanPredixCore.connect(user1).placeOrder(0, 0, 0, ethers.utils.parseEther("100"), 1200);
    await fanPredixCore.connect(user2).placeOrder(0, 0, 1, ethers.utils.parseEther("100"), 1200);

    // Advance time to after market end
    await ethers.provider.send("evm_increaseTime", [3600]);
    await ethers.provider.send("evm_mine");

    // Resolve market
    await fanPredixCore.connect(teamManager).resolveMarket(0, 0);

    // Check claimable winnings
    expect(await fanPredixCore.hasClaimableWinnings(user1.address, 0)).to.be.true;
    expect(await fanPredixCore.hasClaimableWinnings(user2.address, 0)).to.be.false;

    // Redeem winnings
    const initialBalance = await mockToken.balanceOf(user1.address);
    await fanPredixCore.connect(user1).redeemWinnings(0);
    const finalBalance = await mockToken.balanceOf(user1.address);

    expect(finalBalance.sub(initialBalance)).to.be.above(ethers.utils.parseEther("0"));
  });
});