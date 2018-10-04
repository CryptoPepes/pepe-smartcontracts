// solhint-disable-next-line
pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";


contract PepToken is StandardToken {

    string public name = "PEP Token";
    string public symbol = "PEP";
    uint8 public decimals = 18;
    uint256 public constant INITIAL_BALANCE = 45000000 ether;

    constructor() public {
        balances[msg.sender] = INITIAL_BALANCE;
        totalSupply_ = INITIAL_BALANCE;
    }

    /**
     * @dev Allow spender to revoke its own allowance
     * @param _from Address from which allowance should be revoked
     */
    function revokeAllowance(address _from) public {
        allowed[_from][msg.sender] = 0;
    }

}
