// solhint-disable-next-line
pragma solidity ^0.4.4;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


contract RevenueSplit is Ownable {

    address[] public beneficiaries;

    // solhint-disable-next-line no-empty-blocks
    function () public payable {}

    /**
     * Withdraw tokens to beneficiaries
     * @param _token Address of the Token to withdraw
     */
    function withdrawToken(address _token) external { //anyone can call, funds go to beneficiaries anyway
        uint256 totalTokens = ERC20(_token).balanceOf(this);

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            // solhint-disable-next-line max-line-length
            ERC20(_token).transfer(beneficiaries[i], totalTokens / beneficiaries.length); //splits equal portion to every beneficiary
        }
    }

    /**
     * Withdraw Ether to beneficiaries
     */
    function withdrawEther() external { //anyone can call, ether goes to beneficiaries
        uint256 totalEther = address(this).balance;

        for (uint256 i = 0; i < beneficiaries.length; i++) {
            beneficiaries[i].transfer(totalEther / beneficiaries.length); //splits equal portion to every beneficiary
        }
    }

    /**
     * Add a beneficiary. Can only be called by the owner
     * @param _newBeneficiary Beneficiary to add
     */
    function addBeneficiary(address _newBeneficiary) external onlyOwner {
        beneficiaries.push(_newBeneficiary);
    }

    /**
     * Remove a beneficiary. Can only be called by the owner
     * @param _index Index of the beneficiary to remove
     */
    function removeBeneficiary(uint256 _index) external onlyOwner {
        if (_index != beneficiaries.length - 1) {//only replace last if index is smaller than last
            beneficiaries[_index] = beneficiaries[beneficiaries.length - 1];
        }
        beneficiaries.length = beneficiaries.length-1;
    }

    /**
     * Get the beneficiaries
     * @return An array of the beneficiaries
     */
    function getBeneficiaries() public view returns(address[]) {
        return beneficiaries;
    }

}
