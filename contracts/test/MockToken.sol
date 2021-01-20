pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol';
import '../owner/Operator.sol';

contract MockToken is ERC20Burnable, Operator {
    /**
     * @notice Constructs the Oscar Cash ERC-20 contract.
     */
    constructor(string memory name, uint8 decimals, uint256 initSupply) public ERC20('Oscar Cash', name) {
        // Mints 1 Oscar Cash to contract creator for initial Uniswap oracle deployment.
        // Will be burned after oracle deployment
        _setupDecimals(decimals);
        if(initSupply > 0) {
            _mint(msg.sender, initSupply);
        }
    }

    //    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    //        super._beforeTokenTransfer(from, to, amount);
    //        require(
    //            to != operator(),
    //            "Oscar.cash: operator as a recipient is not allowed"
    //        );
    //    }

    /**
     * @notice Operator mints Oscar cash to a recipient
     * @param recipient_ The address of recipient
     * @param amount_ The amount of Oscar cash to mint to
     * @return whether the process has been done
     */
    function mint(address recipient_, uint256 amount_)
        public
        onlyOperator
        returns (bool)
    {
        uint256 balanceBefore = balanceOf(recipient_);
        _mint(recipient_, amount_);
        uint256 balanceAfter = balanceOf(recipient_);

        return balanceAfter > balanceBefore;
    }

    function burn(uint256 amount) public override onlyOperator {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount)
        public
        override
        onlyOperator
    {
        super.burnFrom(account, amount);
    }
}
