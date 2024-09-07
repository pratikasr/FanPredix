const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FanPredix", function () {
  let FanPredix, fanPredix, MockToken, mockToken;
  let owner, admin, teamManager, user1, user2, treasury;
  const PLATFORM_FEE = 250; // 2.5%

  beforeEach(async function () {
    [owner, admin, teamManager, user1, user2, treasury] = await ethers.getSigners();

    // Deploy mock ERC20 token
    MockToken = await ethers.getContractFactory("MockToken");
    mockToken = await MockToken.deploy("Fan Token", "FAN");
    await mockToken.deployed();

    // Deploy FanPredix
    FanPredix = await ethers.getContractFactory("FanPredix");
    fanPredix = await FanPredix.deploy(PLATFORM_FEE, treasury.address);
    await fanPredix.deployed();

    // Grant admin role
    await fanPredix.grantRole(await fanPredix.ADMIN_ROLE(), admin.address);

    // Add team
    await fanPredix.connect(admin).addTeam("Test Team", teamManager.address, mockToken.address);

    // Mint tokens for users
    await mockToken.mint(user1.address, ethers.utils.parseEther("1000"));
    await mockToken.mint(user2.address, ethers.utils.parseEther("1000"));

    // Approve tokens for FanPredix
    await mockToken.connect(user1).approve(fanPredix.address, ethers.constants.MaxUint256);
    await mockToken.connect(user2).approve(fanPredix.address, ethers.constants.MaxUint256);
  });

  async function createMarket() {
    const latestBlock = await ethers.provider.getBlock("latest");
    const startTime = latestBlock.timestamp + 60; // 1 minute from now
    const endTime = startTime + 3600; // 1 hour after start

    await fanPredix.connect(teamManager).createMarket(
      "Sports",
      "Who will win?",
      "Team A vs Team B",
      ["Team A", "Team B"],
      startTime,
      endTime
    );

    return { startTime, endTime };
  }

  describe("Team Management", function () {
    it("Should add a team", async function () {
      const team = await fanPredix.getTeam(teamManager.address);
      expect(team.name).to.equal("Test Team");
      expect(team.teamManager).to.equal(teamManager.address);
      expect(team.fanToken).to.equal(mockToken.address);
    });

    it("Should update a team", async function () {
      await fanPredix.connect(teamManager).updateTeam("Updated Team", mockToken.address);
      const team = await fanPredix.getTeam(teamManager.address);
      expect(team.name).to.equal("Updated Team");
    });
  });

  describe("Market Creation and Management", function () {
    it("Should create a market", async function () {
      const { startTime, endTime } = await createMarket();

      const market = await fanPredix.getMarket(1);
      expect(market.teamManager).to.equal(teamManager.address);
      expect(market.question).to.equal("Who will win?");
      expect(market.startTime).to.equal(startTime);
      expect(market.endTime).to.equal(endTime);
    });

    it("Should place orders and match them", async function () {
      const { startTime } = await createMarket();

      // Advance time to after market start
      await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 1]);
      await ethers.provider.send("evm_mine");

      // Place back order
      await fanPredix.connect(user1).placeOrder(1, 0, 0, ethers.utils.parseEther("100"), 1200);

      // Place lay order
      await fanPredix.connect(user2).placeOrder(1, 0, 1, ethers.utils.parseEther("100"), 1200);

      const backOrders = await fanPredix.getMarketOrders(1, 0, 0);
      const layOrders = await fanPredix.getMarketOrders(1, 0, 1);

      expect(backOrders.length).to.equal(1);
      expect(layOrders.length).to.equal(1);
    });

    it("Should resolve market and allow winning redemption", async function () {
      const { startTime, endTime } = await createMarket();

      // Advance time to after market start
      await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 1]);
      await ethers.provider.send("evm_mine");

      // Place matching orders
      await fanPredix.connect(user1).placeOrder(1, 0, 0, ethers.utils.parseEther("100"), 1200);
      await fanPredix.connect(user2).placeOrder(1, 0, 1, ethers.utils.parseEther("100"), 1200);

      // Advance time to after market end
      await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
      await ethers.provider.send("evm_mine");

      // Resolve market
      await fanPredix.connect(teamManager).resolveMarket(1, 0);

      // Redeem winnings
      const user1BalanceBefore = await mockToken.balanceOf(user1.address);
      await fanPredix.connect(user1).redeemWinnings(1);
      const user1BalanceAfter = await mockToken.balanceOf(user1.address);

      expect(user1BalanceAfter).to.be.gt(user1BalanceBefore);

      // Check that user2 can't redeem
      await expect(fanPredix.connect(user2).redeemWinnings(1)).to.be.revertedWith("revert");
    });
  });

  describe("Order Management", function () {
    it("Should allow cancelling an unmatched order", async function () {
      const { startTime } = await createMarket();

      // Advance time to after market start
      await ethers.provider.send("evm_setNextBlockTimestamp", [startTime + 1]);
      await ethers.provider.send("evm_mine");

      // Place order
      await fanPredix.connect(user1).placeOrder(1, 0, 0, ethers.utils.parseEther("100"), 1200);

      const balanceBefore = await mockToken.balanceOf(user1.address);
      
      // Cancel order
      await fanPredix.connect(user1).cancelOrder(1);

      const balanceAfter = await mockToken.balanceOf(user1.address);

      expect(balanceAfter).to.equal(balanceBefore.add(ethers.utils.parseEther("100")));
    });
  });

  describe("Access Control", function () {
    it("Should only allow admin to add teams", async function () {
      await expect(fanPredix.connect(user1).addTeam("New Team", user2.address, mockToken.address))
        .to.be.revertedWith("AccessControl:");
    });

    it("Should only allow team managers to create markets", async function () {
      const latestBlock = await ethers.provider.getBlock("latest");
      const startTime = latestBlock.timestamp + 60;
      const endTime = startTime + 3600;

      await expect(fanPredix.connect(user1).createMarket(
        "Sports",
        "Who will win?",
        "Team A vs Team B",
        ["Team A", "Team B"],
        startTime,
        endTime
      )).to.be.revertedWith("AccessControl:");
    });
  });
});