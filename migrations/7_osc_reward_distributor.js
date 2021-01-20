const { oscPools, INITIAL_OSC_FOR_POOLS } = require('./pools');

// Pools
// deployed first
const Cash = artifacts.require('Cash')
const InitialCashDistributor = artifacts.require('InitialCashDistributor');
const Referral =  artifacts.require('Referral');

// ============ Main Migration ============

module.exports = async (deployer, network, accounts) => {
  const unit = web3.utils.toBN(10 ** 18);
  const initialCashAmount = unit.muln(INITIAL_OSC_FOR_POOLS).toString();

  const cash = await Cash.deployed();
  const pools = oscPools.map(({contractName}) => artifacts.require(contractName));

  await deployer.deploy(
    InitialCashDistributor,
    cash.address,
    pools.map(p => p.address),
    initialCashAmount,
  );
  const distributor = await InitialCashDistributor.deployed();
  const referral = await Referral.deployed();

  console.log(`Setting distributor to InitialCashDistributor (${distributor.address})`);
  for await (const poolInfo of pools) {
    const pool = await poolInfo.deployed()
    await pool.setRewardDistribution(distributor.address);
    await pool.setRewardReferral(referral.address);
    console.log(`Setting for Pool(${pool.address})`);
  }

  await cash.mint(distributor.address, initialCashAmount);
  console.log(`Deposited ${INITIAL_OSC_FOR_POOLS} OSC to InitialCashDistributor.`);

  await distributor.distribute();
}
