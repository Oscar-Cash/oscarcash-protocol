const contract = require('@truffle/contract');
const { POOL_START_DATE } = require('./pools');
const knownContracts = require('./known-contracts');

const Cash = artifacts.require('Cash');
const Bond = artifacts.require('Bond');
const Share = artifacts.require('Share');
const IERC20 = artifacts.require('IERC20');
const MockDai = artifacts.require('MockDai');

const BondOracle = artifacts.require('Oracle')
const SeigniorageOracle = artifacts.require('Oracle')
const Boardroom = artifacts.require('Boardroom')
const Treasury = artifacts.require('Treasury')
const ERCFund = artifacts.require('SimpleERCFund')

const UniswapV2Factory = artifacts.require('UniswapV2Factory');
const UniswapV2Router02 = artifacts.require('UniswapV2Router02');

const DAY = 86400;
const HOUR = 3600;

async function migration(deployer, network, accounts) {
  let uniswap, uniswapRouter;
  if (['dev'].includes(network)) {
    console.log('Deploying uniswap on dev network.');
    await deployer.deploy(UniswapV2Factory, accounts[0]);
    uniswap = await UniswapV2Factory.deployed();

    await deployer.deploy(UniswapV2Router02, uniswap.address, accounts[0]);
    uniswapRouter = await UniswapV2Router02.deployed();
  } else {
    uniswap = await UniswapV2Factory.at(knownContracts.UniswapV2Factory[network]);
    uniswapRouter = await UniswapV2Router02.at(knownContracts.UniswapV2Router02[network]);
  }

  const dai = network === 'mainnet'
    ? await IERC20.at(knownContracts.DAI[network])
    : await MockDai.deployed();

  // 2. provide liquidity to OSC-DAI and OSS-DAI pair
  // if you don't provide liquidity to OSC-DAI and OSS-DAI pair after step 1 and before step 3,
  //  creating Oracle will fail with NO_RESERVES error.
  const unit = web3.utils.toBN(10 ** 18).toString();
  const max = web3.utils.toBN(10 ** 18).muln(10000).toString();

  const cash = await Cash.deployed();
  const share = await Share.deployed();

  console.log('Approving Uniswap on tokens for liquidity');
  await Promise.all([
    approveIfNot(cash, accounts[0], uniswapRouter.address, max),
    approveIfNot(share, accounts[0], uniswapRouter.address, max),
    approveIfNot(dai, accounts[0], uniswapRouter.address, max),
  ]);

  // WARNING: msg.sender must hold enough DAI to add liquidity to OSC-DAI & OSS-DAI pools
  // otherwise transaction will revert
  console.log('Adding liquidity to pools');
  await uniswapRouter.addLiquidity(
    cash.address, dai.address, unit, unit, unit, unit, accounts[0], deadline(),
  );
  await uniswapRouter.addLiquidity(
    share.address, dai.address, unit, unit, unit, unit, accounts[0],  deadline(),
  );

  console.log(`DAI-OSC pair address: ${await uniswap.getPair(dai.address, cash.address)}`);
  console.log(`DAI-OSS pair address: ${await uniswap.getPair(dai.address, share.address)}`);

  // Deploy boardroom
  await deployer.deploy(Boardroom, cash.address, share.address);

  let startTime = POOL_START_DATE;

  // 2. Deploy seigniorage oracle for the pair between osc and dai
  await deployer.deploy(
    SeigniorageOracle,
    uniswap.address,
    cash.address,
    dai.address,
    1 * DAY,
    startTime,
  );

  // 3. Deploy bond oracle for the pair between osc and dai
  await deployer.deploy(
    BondOracle,
    uniswap.address,
    cash.address,
    dai.address,
    1 * HOUR,
    startTime,
  );

  // 4. Deploy ERCFund
  await deployer.deploy(ERCFund);

  if (network === 'mainnet') {
    startTime += 5 * DAY;
  }

  // 5. Deploy Treasury
  await deployer.deploy(
    Treasury,
    cash.address,
    Bond.address,
    Share.address,
    BondOracle.address,
    SeigniorageOracle.address,
    Boardroom.address,
    ERCFund.address,
    startTime,
  );
}

async function approveIfNot(token, owner, spender, amount) {
  const allowance = await token.allowance(owner, spender);
  if (web3.utils.toBN(allowance).gte(web3.utils.toBN(amount))) {
    return;
  }
  await token.approve(spender, amount);
  console.log(` - Approved ${token.symbol ? (await token.symbol()) : token.address}`);
}

function deadline() {
  // 30 minutes
  return Math.floor(new Date().getTime() / 1000) + 1800;
}

module.exports = migration;