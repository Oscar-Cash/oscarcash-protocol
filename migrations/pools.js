// https://docs.basis.cash/mechanisms/yield-farming
const INITIAL_OSC_FOR_POOLS = 50000;
const INITIAL_OSS_FOR_DAI_OSC = 375000;
const INITIAL_OSS_FOR_DAI_OSS = 125000;

const POOL_START_DATE = Date.parse('2021-01-20T18:30:00Z') / 1000;

const oscPools = [
  { contractName: 'OSCDAIPool', token: 'DAI' },
  { contractName: 'OSCBACPool', token: 'BAC' },
  { contractName: 'OSCUSDCPool', token: 'USDC' },
  { contractName: 'OSCUSDTPool', token: 'USDT' },
  { contractName: 'OSCFRAXPool', token: 'FRAX' },
  { contractName: 'OSCYFIPool', token: 'YFI' },
  { contractName: 'OSCUNIPool', token: 'UNI' },
  { contractName: 'OSCBELPool', token: 'BEL' },
  { contractName: 'OSCSUSHIPool', token: 'SUSHI' },
  { contractName: 'OSCGOFPool', token: 'GOF' },
];

const ossPools = {
  DAIOSC: { contractName: 'DAIOSCLPTokenSharePool', token: 'DAI_OSC-LPv2' },
  DAIOSS: { contractName: 'DAIOSSLPTokenSharePool', token: 'DAI_OSS-LPv2' },
}

module.exports = {
  POOL_START_DATE,
  INITIAL_OSC_FOR_POOLS,
  INITIAL_OSS_FOR_DAI_OSC,
  INITIAL_OSS_FOR_DAI_OSS,
  oscPools,
  ossPools,
};
