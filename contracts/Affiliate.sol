// solhint-disable-next-line
pragma solidity ^0.4.25;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


/** @title Affiliate */
contract Affiliate is Ownable {
    mapping(address => bool) public canSetAffiliate;
    mapping(address => address) public userToAffiliate;

    /** @dev Allows an address to set the affiliate address for a user
      * @param _setter The address that should be allowed
      */
    function setAffiliateSetter(address _setter) public onlyOwner {
        canSetAffiliate[_setter] = true;
    }

    /**
     * @dev Set the affiliate of a user
     * @param _user user to set affiliate for
     * @param _affiliate address to set
     */
    function setAffiliate(address _user, address _affiliate) public {
        require(canSetAffiliate[msg.sender]);
        if (userToAffiliate[_user] == address(0)) {
            userToAffiliate[_user] = _affiliate;
        }
    }

}
