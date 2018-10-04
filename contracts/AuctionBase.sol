// solhint-disable-next-line
pragma solidity ^0.4.24;

import "./Beneficiary.sol";
import "./Affiliate.sol";
import "./interfaces/PepeInterface.sol";


/** @title AuctionBase */
contract AuctionBase is Beneficiary {
    mapping(uint256 => PepeAuction) public auctions;//maps pepes to auctions
    PepeInterface public pepeContract;
    Affiliate public affiliateContract;
    uint256 public fee = 37500; //in 1 10000th of a percent so 3.75% at the start
    uint256 public constant FEE_DIVIDER = 1000000; //Perhaps needs better name?

    struct PepeAuction {
        address seller;
        uint256 pepeId;
        uint64 auctionBegin;
        uint64 auctionEnd;
        uint256 beginPrice;
        uint256 endPrice;
    }

    event AuctionWon(uint256 indexed pepe, address indexed winner, address indexed seller);
    event AuctionStarted(uint256 indexed pepe, address indexed seller);
    event AuctionFinalized(uint256 indexed pepe, address indexed seller);

    constructor(address _pepeContract, address _affiliateContract) public {
        pepeContract = PepeInterface(_pepeContract);
        affiliateContract = Affiliate(_affiliateContract);
    }

    /**
     * @dev Return a pepe from a auction that has passed
     * @param  _pepeId the id of the pepe to save
     */
    function savePepe(uint256 _pepeId) external {
        // solhint-disable-next-line not-rely-on-time
        require(auctions[_pepeId].auctionEnd < now);//auction must have ended
        require(pepeContract.transfer(auctions[_pepeId].seller, _pepeId));//transfer pepe back to seller

        emit AuctionFinalized(_pepeId, auctions[_pepeId].seller);

        delete auctions[_pepeId];//delete auction
    }

    /**
     * @dev change the fee on pepe sales. Can only be lowerred
     * @param _fee The new fee to set. Must be lower than current fee
     */
    function changeFee(uint256 _fee) external onlyOwner {
        require(_fee < fee);//fee can not be raised
        fee = _fee;
    }

    /**
     * @dev Start a auction
     * @param  _pepeId Pepe to sell
     * @param  _beginPrice Price at which the auction starts
     * @param  _endPrice Ending price of the auction
     * @param  _duration How long the auction should take
     */
    function startAuction(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration) public {
        require(pepeContract.transferFrom(msg.sender, address(this), _pepeId));
        // solhint-disable-next-line not-rely-on-time
        require(now > auctions[_pepeId].auctionEnd);//can only start new auction if no other is active

        PepeAuction memory auction;

        auction.seller = msg.sender;
        auction.pepeId = _pepeId;
        // solhint-disable-next-line not-rely-on-time
        auction.auctionBegin = uint64(now);
        // solhint-disable-next-line not-rely-on-time
        auction.auctionEnd = uint64(now) + _duration;
        require(auction.auctionEnd > auction.auctionBegin);
        auction.beginPrice = _beginPrice;
        auction.endPrice = _endPrice;

        auctions[_pepeId] = auction;

        emit AuctionStarted(_pepeId, msg.sender);
    }

    /**
     * @dev directly start a auction from the PepeBase contract
     * @param  _pepeId Pepe to put on auction
     * @param  _beginPrice Price at which the auction starts
     * @param  _endPrice Ending price of the auction
     * @param  _duration How long the auction should take
     * @param  _seller The address selling the pepe
     */
    // solhint-disable-next-line max-line-length
    function startAuctionDirect(uint256 _pepeId, uint256 _beginPrice, uint256 _endPrice, uint64 _duration, address _seller) public {
        require(msg.sender == address(pepeContract)); //can only be called by pepeContract
        //solhint-disable-next-line not-rely-on-time
        require(now > auctions[_pepeId].auctionEnd);//can only start new auction if no other is active

        PepeAuction memory auction;

        auction.seller = _seller;
        auction.pepeId = _pepeId;
        // solhint-disable-next-line not-rely-on-time
        auction.auctionBegin = uint64(now);
        // solhint-disable-next-line not-rely-on-time
        auction.auctionEnd = uint64(now) + _duration;
        require(auction.auctionEnd > auction.auctionBegin);
        auction.beginPrice = _beginPrice;
        auction.endPrice = _endPrice;

        auctions[_pepeId] = auction;

        emit AuctionStarted(_pepeId, _seller);
    }

  /**
   * @dev Calculate the current price of a auction
   * @param  _pepeId the pepeID to calculate the current price for
   * @return currentBid the current price for the auction
   */
    function calculateBid(uint256 _pepeId) public view returns(uint256 currentBid) {
        PepeAuction storage auction = auctions[_pepeId];
        // solhint-disable-next-line not-rely-on-time
        uint256 timePassed = now - auctions[_pepeId].auctionBegin;

        // If auction ended return auction end price.
        // solhint-disable-next-line not-rely-on-time
        if (now >= auction.auctionEnd) {
            return auction.endPrice;
        } else {
            // Can be negative
            int256 priceDifference = int256(auction.endPrice) - int256(auction.beginPrice);
            // Always positive
            int256 duration = int256(auction.auctionEnd) - int256(auction.auctionBegin);

            // As already proven in practice by CryptoKitties:
            //  timePassed -> 64 bits at most
            //  priceDifference -> 128 bits at most
            //  timePassed * priceDifference -> 64 + 128 bits at most
            int256 priceChange = priceDifference * int256(timePassed) / duration;

            // Will be positive, both operands are less than 256 bits
            int256 price = int256(auction.beginPrice) + priceChange;

            return uint256(price);
        }
    }

  /**
   * @dev collect the fees from the auction
   */
    function getFees() public {
        beneficiary.transfer(address(this).balance);
    }


}
