const Boardroom = artifacts.require('Boardroom');
const Treasury = artifacts.require('Treasury');
const Cash = artifacts.require('Cash');
const Bond = artifacts.require('Bond');
const Share = artifacts.require('Share');
const Timelock = artifacts.require('Timelock');
const Referral = artifacts.require('Referral');
const DAY = 86400;

module.exports = async (deployer, network, accounts) => {
  const cash = await Cash.deployed();
  const share = await Share.deployed();
  const bond = await Bond.deployed();
  const treasury = await Treasury.deployed();
  const boardroom = await Boardroom.deployed();
  const referral = await Referral.deployed();
  
  const delay = network === 'mainnet' ? 2 * DAY : 20 * 60;
  console.log('delay=' + delay)
  const timelock = await deployer.deploy(Timelock, accounts[0], delay);

  // Token Setting
  for await (const contract of [ cash, share, bond ]) {
    await contract.transferOperator(treasury.address);
    await contract.transferOwnership(treasury.address);
  }

  // boardroom & treasury Setting
  await boardroom.transferOperator(treasury.address);
  await boardroom.transferOwnership(timelock.address);
  await treasury.transferOperator(timelock.address);
  await treasury.transferOwnership(timelock.address);

  // Referral Setting
  await referral.transferOperator(timelock.address);
  await referral.transferOwnership(timelock.address);
  console.log(`Transferred the operator role from the deployer (${accounts[0]}) to Treasury (${Treasury.address})`);
}
