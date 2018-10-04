// solhint-disable-next-line
pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


/** @title Beneficiary */
contract Beneficiary is Ownable {
    address public beneficiary;

    constructor() public {
        beneficiary = msg.sender;
    }

    /**
     * @dev Change the beneficiary address
     * @param _beneficiary Address of the new beneficiary
     */
    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }
}
