const hre = require("hardhat");
const { ethers } = require("hardhat");
const { getPrivateKey } = require('../getPrivateKey');
require('dotenv').config();

async function main() {
  try {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Log balance
    const balance = await deployer.getBalance();
    console.log("Account balance:", ethers.utils.formatEther(balance), "CHZ");

    // Set up the gas price
    const gasPrice = await ethers.provider.getGasPrice();
    console.log("Current gas price:", ethers.utils.formatUnits(gasPrice, "gwei"), "gwei");

    // Get the contract factory
    const FanPredix = await ethers.getContractFactory("FanPredix");
    
    // Check contract size
    const bytecode = FanPredix.bytecode;
    const bytecodeSize = bytecode.length / 2 - 1;
    console.log("Contract bytecode size:", bytecodeSize, "bytes");
    
    if (bytecodeSize > 24576) {
      console.error("Contract size exceeds 24KB limit. Please optimize your contract.");
      process.exit(1);
    }

    // Estimate gas
    const estimatedGas = await FanPredix.signer.estimateGas(
      FanPredix.getDeployTransaction(
        250, // Platform fee (2.5%)
        ethers.utils.parseEther("10"), // Minimum bet amount (10 CHZ)
        deployer.address // Use deployer as treasury for now
      )
    );
    console.log("Estimated gas:", estimatedGas.toString());

    // Set a custom gas limit (you can adjust this)
    const gasLimit = estimatedGas.mul(120).div(100); // Add 20% buffer
    console.log("Setting gas limit to:", gasLimit.toString());

    // Deploy with specific gas settings
    const fanPredix = await FanPredix.deploy(
      250, // Platform fee (2.5%)
      ethers.utils.parseEther("10"), // Minimum bet amount (10 CHZ)
      deployer.address, // Use deployer as treasury for now
      { 
        gasPrice: gasPrice,
        gasLimit: gasLimit
      }
    );

    await fanPredix.deployed();

    console.log("FanPredix deployed to:", fanPredix.address);
    
    // Log final cost
    const deploymentReceipt = await fanPredix.deployTransaction.wait();
    const actualGasUsed = deploymentReceipt.gasUsed;
    const actualCost = actualGasUsed.mul(gasPrice);
    console.log("Actual gas used:", actualGasUsed.toString());
    console.log("Actual cost:", ethers.utils.formatEther(actualCost), "CHZ");
  } catch (error) {
    console.error("Deployment failed:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });