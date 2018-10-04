// solhint-disable-next-line
pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Haltable is Ownable {
    uint256 public haltTime; //when the contract was halted
    bool public halted;//is the contract halted?
    uint256 public haltDuration;
    uint256 public maxHaltDuration = 8 weeks;//how long the contract can be halted

    modifier stopWhenHalted {
        require(!halted);
        _;
    }

    modifier onlyWhenHalted {
        require(halted);
        _;
    }

    /**
     * @dev Halt the contract for a set time smaller than maxHaltDuration
     * @param  _duration Duration how long the contract should be halted. Must be smaller than maxHaltDuration
     */
    function halt(uint256 _duration) public onlyOwner {
        require(haltTime == 0); //cannot halt if it was halted before
        require(_duration <= maxHaltDuration);//cannot halt for longer than maxHaltDuration
        haltDuration = _duration;
        halted = true;
        // solhint-disable-next-line not-rely-on-time
        haltTime = now;
    }

    /**
     * @dev Unhalt the contract. Can only be called by the owner or when the haltTime has passed
     */
    function unhalt() public {
        // solhint-disable-next-line
        require(now > haltTime + haltDuration || msg.sender == owner);//unhalting is only possible when haltTime has passed or the owner unhalts
        halted = false;
    }

}
