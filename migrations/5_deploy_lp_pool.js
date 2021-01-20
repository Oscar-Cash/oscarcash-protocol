const knownContracts = require('./known-contracts');
const { POOL_START_DATE } = require('./pools');

const Cash = artifacts.require('Cash');
const Share = artifacts.require('Share');
const Oracle = artifacts.require('Oracle');
const MockDai = artifacts.require('MockDai');

const DAIOSCLPToken_OSSPool = artifacts.require('DAIOSCLPTokenSharePool')
const DAIOSSLPToken_OSSPool = artifacts.require('DAIOSSLPTokenSharePool')

const UniswapV2Factory = artifacts.require('UniswapV2Factory');
const ZERO_ADDR = '0x0000000000000000000000000000000000000000';
module.exports = async (deployer, network, accounts) => {
  const uniswapFactory = ['dev'].includes(network)
    ? await UniswapV2Factory.deployed()
    : await UniswapV2Factory.at(knownContracts.UniswapV2Factory[network]);
  const dai = network === 'mainnet'
    ? await IERC20.at(knownContracts.DAI[network])
    : await MockDai.deployed();

  const oracle = await Oracle.deployed();

  const dai_osc_lpt = await oracle.pairFor(uniswapFactory.address, Cash.address, dai.address);
  const dai_oss_lpt = await oracle.pairFor(uniswapFactory.address, Share.address, dai.address);

  await deployer.deploy(DAIOSCLPToken_OSSPool, Share.address, dai_osc_lpt, knownContracts['RiskFund'][network]||ZERO_ADDR, POOL_START_DATE);
  await deployer.deploy(DAIOSSLPToken_OSSPool, Share.address, dai_oss_lpt, knownContracts['RiskFund'][network]||ZERO_ADDR, POOL_START_DATE);
};
