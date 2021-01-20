pragma solidity ^0.6.0;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '../lib/UniswapV2Library.sol';
import './IUniswapV2Pair.sol';
import './IFreeFromUpTo.sol';
import './IGasSponsor.sol';

abstract contract IGasDiscount{
    using SafeMath for uint256;

    uint256 internal constant FLAG_ENABLE_CHI_BURN = 1;
    uint256 internal constant FLAG_ENABLE_CHI_BURN_BY_ORIGIN = 2;
    uint256 internal constant FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP = 4;
    // mainnet
    IFreeFromUpTo constant public chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    // ropsten
    // IFreeFromUpTo constant public chi = IFreeFromUpTo(0xf385ae3337a5FB26D56e75222948583EB2b80740);
    // rinkeby todo
    // IFreeFromUpTo constant public chi = IFreeFromUpTo(0xC93F482b9a4757E95b7CB8bBca96439606Ea1930);
    
    // flag = 1,2,3,4
    modifier discountGas(address _gasSponsor, uint256 _flag) {
        //chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
        if(_flag & (FLAG_ENABLE_CHI_BURN | FLAG_ENABLE_CHI_BURN_BY_ORIGIN) > 0) {
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            address freeFrom = (_flag & FLAG_ENABLE_CHI_BURN_BY_ORIGIN) > 0 ? tx.origin : msg.sender;
            if(chi.balanceOf(freeFrom) > 0) {
                chi.freeFromUpTo(freeFrom, (gasSpent + 14154) / 41947);   
            }
        } else if ((_flag & FLAG_ENABLE_REFERRAL_GAS_SPONSORSHIP) > 0 && _gasSponsor != address(0)) {
            uint256 gasStart = gasleft();
            _;
            uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            IGasSponsor(_gasSponsor).makeGasDiscount(gasSpent, msg.data);
        } else {
            _;
        }
    }

}