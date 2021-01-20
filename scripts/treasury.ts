import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address';
import { keccak256, ParamType } from 'ethers/lib/utils';
import { network, ethers } from 'hardhat';

import deployments from '../deployments/ropsten.json';
import { encodeParameters, wait } from './utils';


async function main() {

  const { provider } = ethers;
  const [operator] = await ethers.getSigners();
  
  const estimateGasPrice = await provider.getGasPrice();
  const gasPrice = estimateGasPrice.mul(3).div(2);
  console.log(`Gas Price: ${ethers.utils.formatUnits(gasPrice, 'gwei')} gwei`);

  const override = { gasPrice };

  const treasury = await ethers.getContractAt('Treasury', deployments.Treasury);

  const bondPrice = await treasury.getBondOraclePrice();
  const seigniorage = await treasury.getSeigniorageOraclePrice();
  
  console.log(`bondPrice:${ethers.utils.formatUnits(bondPrice, 'ether')}  seigniorage:$${ethers.utils.formatUnits(seigniorage, 'ether')} address:${operator.address}`);

  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
