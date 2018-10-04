// solhint-disable-next-line
pragma solidity ^0.4.4;

import "openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./PepeBase.sol";


contract PepeGrinder is StandardToken, Ownable {

    address public pepeContract;
    address public miner;
    uint256[] public pepes;
    mapping(address => bool) public dusting;

    string public name = "CryptoPepes DUST";
    string public symbol = "DPEP";
    uint8 public decimals = 18;

    uint256 public constant DUST_PER_PEPE = 100 ether;

    constructor(address _pepeContract) public {
        pepeContract = _pepeContract;
    }

    /**
     * Set the mining contract. Can only be set once
     * @param _miner The address of the miner contract
     */
    function setMiner(address _miner) public onlyOwner {
        require(miner == address(0));// can only be set once
        miner = _miner;
    }

    /**
     * Gets called by miners who wanna dust their mined Pepes
     */
    function setDusting() public {
        dusting[msg.sender] = true;
    }

    /**
     * Dust a pepe to pepeDust
     * @param _pepeId Pepe to dust
     * @param _miner address of the miner
     */
    function dustPepe(uint256 _pepeId, address _miner) public {
        require(msg.sender == miner);
        balances[_miner] += DUST_PER_PEPE;
        pepes.push(_pepeId);
        totalSupply_ += DUST_PER_PEPE;
        emit Transfer(address(0), _miner, DUST_PER_PEPE);
    }

    /**
     * Convert dust into a Pepe
     */
    function claimPepe() public {
        require(balances[msg.sender] >= DUST_PER_PEPE);

        balances[msg.sender] -= DUST_PER_PEPE; //change balance and total supply
        totalSupply_ -= DUST_PER_PEPE;

        PepeBase(pepeContract).transfer(msg.sender, pepes[pepes.length-1]);//transfer pepe
        pepes.length -= 1;
        emit Transfer(msg.sender, address(0), DUST_PER_PEPE);
    }

}
