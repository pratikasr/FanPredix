const ethers = require('ethers');
require('dotenv').config();

function getPrivateKey(mnemonic, index = 0) {
    if (!mnemonic) {
      console.error('Error: Mnemonic not found in .env file');
      process.exit(1);
    }
    console.log('Deriving private key from mnemonic...');
    const hdNode = ethers.utils.HDNode.fromMnemonic(mnemonic);
    const wallet = hdNode.derivePath(`m/44'/60'/0'/0/${index}`);
    console.log('Derived address:', wallet.address);
    return wallet.privateKey;
  }

const mnemonic = process.env.MNEMONIC;
if (mnemonic) {
  const privateKey = getPrivateKey(mnemonic);
  console.log('Private Key (first 10 characters):', privateKey.substring(0, 10) + '...');
} else {
  console.error('Error: MNEMONIC not found in .env file');
}

module.exports = { getPrivateKey };