// solhint-disable-next-line
pragma solidity ^0.4.19;

import "./AuctionBase.sol";


//Most functionality is in the AuctionBase contract.
//This contract is to buy pepes on the auction.
contract PepeAuctionSale is AuctionBase {
  // solhint-disable-next-line
    constructor(address _pepeContract, address _affiliateContract) AuctionBase(_pepeContract, _affiliateContract) public {

    }

    /**
     * @dev Buy a pepe from the auction
     * @param  _pepeId The id of the pepe to buy
     */
    function buyPepe(uint256 _pepeId) public payable {
        PepeAuction storage auction = auctions[_pepeId];

        // solhint-disable-next-line not-rely-on-time
        require(now < auction.auctionEnd);// auction must be still going

        uint256 price = calculateBid(_pepeId);
        require(msg.value >= price); //must send enough ether
        uint256 totalFee = price * fee / FEE_DIVIDER; //safe math needed?

        //Send ETH to seller
        auction.seller.transfer(price - totalFee);
        //send ETH to beneficiary

        // solhint-disable-next-line
        if(affiliateContract.userToAffiliate(msg.sender) != address(0) && affiliateContract.userToAffiliate(msg.sender).send(totalFee / 2)) { //if user has affiliate
            //nothing to do here. Just to suppress warning
        }
        //Send pepe to buyer
        if (!pepeContract.transfer(msg.sender, _pepeId)) {
            revert(); //can't complete transfer if this fails
        }

        emit AuctionWon(_pepeId, msg.sender, auction.seller);

        if (msg.value > price) { //return ether send to much
            msg.sender.transfer(msg.value - price);
        }

        delete auctions[_pepeId];//deletes auction
    }

    /**
     * @dev Buy a pepe and send along affiliate address
     * @param  _pepeId The id of the pepe to buy
     * @param  _affiliate address of the affiliate to set
     */
    // solhint-disable-next-line func-order
    function buyPepeAffiliated(uint256 _pepeId, address _affiliate) external payable {
        affiliateContract.setAffiliate(msg.sender, _affiliate);
        buyPepe(_pepeId);
    }

}
