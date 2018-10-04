// solhint-disable-next-line
pragma solidity ^0.4.24;

import "./AuctionBase.sol";


/** @title CozyTimeAuction */
contract CozyTimeAuction is AuctionBase {
    // solhint-disable-next-line
    constructor (address _pepeContract, address _affiliateContract) AuctionBase(_pepeContract, _affiliateContract) public {

    }

    /**
     * @dev Start an auction
     * @param  _pepeId The id of the pepe to start the auction for
     * @param  _beginPrice Start price of the auction
     * @param  _endPrice End price of the auction
     * @param  _duration How long the auction should take
     */
    function startAuction(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration) public {
        // solhint-disable-next-line not-rely-on-time
        require(pepeContract.getCozyAgain(_pepeId) <= now);//need to have this extra check
        super.startAuction(_pepeId, _beginPrice, _endPrice, _duration);
    }

    /**
     * @dev Start a auction direclty from the PepeBase smartcontract
     * @param  _pepeId The id of the pepe to start the auction for
     * @param  _beginPrice Start price of the auction
     * @param  _endPrice End price of the auction
     * @param  _duration How long the auction should take
     * @param  _seller The address of the seller
     */
    // solhint-disable-next-line max-line-length
    function startAuctionDirect(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration, address _seller) public {
        // solhint-disable-next-line not-rely-on-time
        require(pepeContract.getCozyAgain(_pepeId) <= now);//need to have this extra check
        super.startAuctionDirect(_pepeId, _beginPrice, _endPrice, _duration, _seller);
    }

    /**
     * @dev Buy cozy right from the auction
     * @param  _pepeId Pepe to cozy with
     * @param  _cozyCandidate the pepe to cozy with
     * @param  _candidateAsFather Is the _cozyCandidate father?
     * @param  _pepeReceiver address receiving the pepe after cozy time
     */
    // solhint-disable-next-line max-line-length
    function buyCozy(uint256 _pepeId, uint256 _cozyCandidate, bool _candidateAsFather, address _pepeReceiver) public payable {
        require(address(pepeContract) == msg.sender); //caller needs to be the PepeBase contract

        PepeAuction storage auction = auctions[_pepeId];
        // solhint-disable-next-line not-rely-on-time
        require(now < auction.auctionEnd);// auction must be still going

        uint256 price = calculateBid(_pepeId);
        require(msg.value >= price);//must send enough ether
        uint256 totalFee = price * fee / FEE_DIVIDER; //safe math needed?

        //Send ETH to seller
        auction.seller.transfer(price - totalFee);
        //send ETH to beneficiary

        address affiliate = affiliateContract.userToAffiliate(_pepeReceiver);

        //solhint-disable-next-line
        if (affiliate != address(0) && affiliate.send(totalFee / 2)) { //if user has affiliate
            //nothing just to suppress warning
        }

        //actual cozytiming
        if (_candidateAsFather) {
            if (!pepeContract.cozyTime(auction.pepeId, _cozyCandidate, _pepeReceiver)) {
                revert();
            }
        } else {
          // Swap around the two pepes, they have no set gender, the user decides what they are.
            if (!pepeContract.cozyTime(_cozyCandidate, auction.pepeId, _pepeReceiver)) {
                revert();
            }
        }

        //Send pepe to seller of auction
        if (!pepeContract.transfer(auction.seller, _pepeId)) {
            revert(); //can't complete transfer if this fails
        }

        if (msg.value > price) { //return ether send to much
            _pepeReceiver.transfer(msg.value - price);
        }

        emit AuctionWon(_pepeId, _pepeReceiver, auction.seller);//emit event

        delete auctions[_pepeId];//deletes auction
    }

    /**
     * @dev Buy cozytime and pass along affiliate
     * @param  _pepeId Pepe to cozy with
     * @param  _cozyCandidate the pepe to cozy with
     * @param  _candidateAsFather Is the _cozyCandidate father?
     * @param  _pepeReceiver address receiving the pepe after cozy time
     * @param  _affiliate Affiliate address to set
     */
    //solhint-disable-next-line max-line-length
    function buyCozyAffiliated(uint256 _pepeId, uint256 _cozyCandidate, bool _candidateAsFather, address _pepeReceiver, address _affiliate) public payable {
        affiliateContract.setAffiliate(_pepeReceiver, _affiliate);
        buyCozy(_pepeId, _cozyCandidate, _candidateAsFather, _pepeReceiver);
    }
}
