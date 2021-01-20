const { oscPools } = require('./pools');

const Referral = artifacts.require('Referral')

const DAIOSCLPToken_OSSPool = artifacts.require('DAIOSCLPTokenSharePool')
const DAIOSSLPToken_OSSPool = artifacts.require('DAIOSSLPTokenSharePool')

module.exports = async (deployer, network, accounts) => {
  await deployer.deploy(Referral);

  const referral = await Referral.deployed();

  const pools = oscPools.map(({contractName}) => artifacts.require(contractName));

  // Set osc pools
  for await (const poolInfo of pools) {
    await poolInfo.deployed().then(pool => {
          console.log(`Setting referral permission to OSCPool (${pool.address})`);
          referral.setAdminStatus(pool.address, true)
        });
  }
 
  // Set oss pools
  await DAIOSCLPToken_OSSPool.deployed().then(pool => {
    console.log(`Setting referral permission to OSC-DAI Pool (${pool.address})`);
    referral.setAdminStatus(pool.address, true)
  });

  await DAIOSSLPToken_OSSPool.deployed().then(pool => {
    console.log(`Setting referral permission to OSS-DAI Pool (${pool.address})`);
    referral.setAdminStatus(pool.address, true)
  });
};
