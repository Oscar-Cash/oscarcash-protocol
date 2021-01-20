const knownContracts = require('./known-contracts');
const { oscPools, POOL_START_DATE } = require('./pools');

// Tokens
// deployed first
const Cash = artifacts.require('Cash');
const MockDai = artifacts.require('MockDai');
const ZERO_ADDR = '0x0000000000000000000000000000000000000000';
// ============ Main Migration ============
module.exports = async (deployer, network, accounts) => {
  for await (const { contractName, token } of oscPools) {
    const tokenAddress = knownContracts[token][network] || MockDai.address;
    if (!tokenAddress) {
      // network is mainnet, so MockDai is not available
      throw new Error(`Address of ${token} is not registered on migrations/known-contracts.js!`);
    }

    const contract = artifacts.require(contractName);
    await deployer.deploy(contract, Cash.address, tokenAddress, knownContracts['RiskFund'][network]||ZERO_ADDR, POOL_START_DATE);
  }
};
