pragma solidity ^0.4.4;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library ExtendedMath {
  //return the smaller of the two inputs (a or b)
  function limitLessThan(uint a, uint b) internal pure returns (uint c) {
    if(a > b) return b;
    return a;
  }
}
