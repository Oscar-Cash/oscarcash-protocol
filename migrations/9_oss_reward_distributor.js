const {
  ossPools,
  INITIAL_OSS_FOR_DAI_OSC,
  INITIAL_OSS_FOR_DAI_OSS,
} = require('./pools');

// Pools
// deployed first
const Share = artifacts.require('Share');
const InitialShareDistributor = artifacts.require('InitialShareDistributor');
const Referral =  artifacts.require('Referral');

// ============ Main Migration ============

async function migration(deployer, network, accounts) {
  const unit = web3.utils.toBN(10 ** 18);
  const totalBalanceForDAIOSC = unit.muln(INITIAL_OSS_FOR_DAI_OSC)
  const totalBalanceForDAIOSS = unit.muln(INITIAL_OSS_FOR_DAI_OSS)
  const totalBalance = totalBalanceForDAIOSC.add(totalBalanceForDAIOSS);

  const share = await Share.deployed();

  const lpPoolDAIOSC = artifacts.require(ossPools.DAIOSC.contractName);
  const lpPoolDAIOSS = artifacts.require(ossPools.DAIOSS.contractName);

  await deployer.deploy(
    InitialShareDistributor,
    share.address,
    lpPoolDAIOSC.address,
    totalBalanceForDAIOSC.toString(),
    lpPoolDAIOSS.address,
    totalBalanceForDAIOSS.toString(),
  );
  const distributor = await InitialShareDistributor.deployed();
  const referral = await Referral.deployed();

  await share.mint(distributor.address, totalBalance.toString());
  console.log(`Deposited ${totalBalance} OSS to InitialShareDistributor.`);

  console.log(`Setting distributor to InitialShareDistributor (${distributor.address})`);
  await lpPoolDAIOSC.deployed().then(pool => {
     pool.setRewardDistribution(distributor.address);
     pool.setRewardReferral(referral.address);
  });
  await lpPoolDAIOSS.deployed().then(pool => {
    pool.setRewardDistribution(distributor.address);
    pool.setRewardReferral(referral.address);
  });

  await distributor.distribute();
}

module.exports = migration;
