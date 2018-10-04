// solhint-disable-next-line
pragma solidity ^0.4.24;

// solhint-disable func-order

import "./Genetic.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./Usernames.sol";
import "./AuctionBase.sol";
import "./CozyTimeAuction.sol";
import "./Haltable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./interfaces/ERC721TokenReceiver.sol";


contract PepeBase is Genetic, Ownable, Usernames, Haltable {

    uint32[15] public cozyCoolDowns = [ //determined by generation / 2
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(15 minutes),
        uint32(30 minutes),
        uint32(45 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days),
        uint32(7 days)
    ];

    struct Pepe {
        address master; //The master of the pepe
        uint256[2] genotype; //all genes stored here
        uint64 canCozyAgain; //time when pepe can have nice time again
        uint64 generation; //what generation?
        uint64 father; //father of this pepe
        uint64 mother; //mommy of this pepe
        uint8 coolDownIndex;
    }

    mapping(uint256 => bytes32) public pepeNames;

    //stores all pepes
    Pepe[] public pepes;

    bool public implementsERC721 = true; //signal erc721 support

    // solhint-disable-next-line const-name-snakecase
    string public constant name = "Crypto Pepe";
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "CPEP";

    mapping(address => uint256[]) private wallets;
    mapping(address => uint256) public balances; //amounts of pepes per address
    mapping(uint256 => address) public approved; //pepe index to address approved to transfer
    mapping(address => mapping(address => bool)) public approvedForAll;

    uint256 public zeroGenPepes; //how many zero gen pepes are mined
    uint256 public constant MAX_PREMINE = 100;//how many pepes can be premined
    uint256 public constant MAX_ZERO_GEN_PEPES = 1100; //max number of zero gen pepes
    address public miner; //address of the miner contract

    modifier onlyPepeMaster(uint256 _pepeId) {
        require(pepes[_pepeId].master == msg.sender);
        _;
    }

    modifier onlyAllowed(uint256 _tokenId) {
        // solhint-disable-next-line max-line-length
        require(msg.sender == pepes[_tokenId].master || msg.sender == approved[_tokenId] || approvedForAll[pepes[_tokenId].master][msg.sender]); //check if msg.sender is allowed
        _;
    }

    event PepeBorn(uint256 indexed mother, uint256 indexed father, uint256 indexed pepeId);
    event PepeNamed(uint256 indexed pepeId);

    constructor() public {

        Pepe memory pepe0 = Pepe({
            master: 0x0,
            genotype: [uint256(0), uint256(0)],
            canCozyAgain: 0,
            father: 0,
            mother: 0,
            generation: 0,
            coolDownIndex: 0
        });

        pepes.push(pepe0);
    }

    /**
     * @dev Internal function that creates a new pepe
     * @param  _genoType DNA of the new pepe
     * @param  _mother The ID of the mother
     * @param  _father The ID of the father
     * @param  _generation The generation of the new Pepe
     * @param  _master The owner of this new Pepe
     * @return The ID of the newly generated Pepe
     */
    // solhint-disable-next-line max-line-length
    function _newPepe(uint256[2] _genoType, uint64 _mother, uint64 _father, uint64 _generation, address _master) internal returns (uint256 pepeId) {
        uint8 tempCoolDownIndex;

        tempCoolDownIndex = uint8(_generation / 2);

        if (_generation > 28) {
            tempCoolDownIndex = 14;
        }

        Pepe memory _pepe = Pepe({
            master: _master, //The master of the pepe
            genotype: _genoType, //all genes stored here
            canCozyAgain: 0, //time when pepe can have nice time again
            father: _father, //father of this pepe
            mother: _mother, //mommy of this pepe
            generation: _generation, //what generation?
            coolDownIndex: tempCoolDownIndex
        });

        if (_generation == 0) {
            zeroGenPepes += 1; //count zero gen pepes
        }

        //push returns the new length, use it to get a new unique id
        pepeId = pepes.push(_pepe) - 1;

        //add it to the wallet of the master of the new pepe
        addToWallet(_master, pepeId);

        emit PepeBorn(_mother, _father, pepeId);
        emit Transfer(address(0), _master, pepeId);

        return pepeId;
    }

    /**
     * @dev Set the miner contract. Can only be called once
     * @param _miner Address of the miner contract
     */
    function setMiner(address _miner) public onlyOwner {
        require(miner == address(0));//can only be set once
        miner = _miner;
    }

    /**
     * @dev Mine a new Pepe. Can only be called by the miner contract.
     * @param  _seed Seed to be used for the generation of the DNA
     * @param  _receiver Address receiving the newly mined Pepe
     * @return The ID of the newly mined Pepe
     */
    function minePepe(uint256 _seed, address _receiver) public stopWhenHalted returns(uint256) {
        require(msg.sender == miner);//only miner contract can call
        require(zeroGenPepes < MAX_ZERO_GEN_PEPES);

        return _newPepe(randomDNA(_seed), 0, 0, 0, _receiver);
    }

    /**
     * @dev Premine pepes. Can only be called by the owner and is limited to MAX_PREMINE
     * @param  _amount Amount of Pepes to premine
     */
    function pepePremine(uint256 _amount) public onlyOwner stopWhenHalted {
        for (uint i = 0; i < _amount; i++) {
            require(zeroGenPepes <= MAX_PREMINE);//can only generate set amount during premine
            //create a new pepe
            // 1) who's genes are based on hash of the timestamp and the number of pepes
            // 2) who has no mother or father
            // 3) who is generation zero
            // 4) who's master is the manager

            // solhint-disable-next-line
            _newPepe(randomDNA(uint256(keccak256(abi.encodePacked(block.timestamp, pepes.length)))), 0, 0, 0, owner);

        }
    }

    /**
     * @dev CozyTime two Pepes together
     * @param  _mother The mother of the new Pepe
     * @param  _father The father of the new Pepe
     * @param  _pepeReceiver Address receiving the new Pepe
     * @return If it was a success
     */
    function cozyTime(uint256 _mother, uint256 _father, address _pepeReceiver) external stopWhenHalted returns (bool) {
        //cannot cozyTime with itself
        require(_mother != _father);
        //caller has to either be master or approved for mother
        // solhint-disable-next-line max-line-length
        require(pepes[_mother].master == msg.sender || approved[_mother] == msg.sender || approvedForAll[pepes[_mother].master][msg.sender]);
        //caller has to either be master or approved for father
        // solhint-disable-next-line max-line-length
        require(pepes[_father].master == msg.sender || approved[_father] == msg.sender || approvedForAll[pepes[_father].master][msg.sender]);
        //require both parents to be ready for cozytime
        // solhint-disable-next-line not-rely-on-time
        require(now > pepes[_mother].canCozyAgain && now > pepes[_father].canCozyAgain);
        //require both mother parents not to be father
        require(pepes[_mother].mother != _father && pepes[_mother].father != _father);
        //require both father parents not to be mother
        require(pepes[_father].mother != _mother && pepes[_father].father != _mother);

        Pepe storage father = pepes[_father];
        Pepe storage mother = pepes[_mother];


        approved[_father] = address(0);
        approved[_mother] = address(0);

        uint256[2] memory newGenotype = breed(father.genotype, mother.genotype, pepes.length);

        uint64 newGeneration;

        newGeneration = mother.generation + 1;
        if (newGeneration < father.generation + 1) { //if father generation is bigger
            newGeneration = father.generation + 1;
        }

        _handleCoolDown(_mother);
        _handleCoolDown(_father);

        //sets pepe birth when mother is done
        // solhint-disable-next-line max-line-length
        pepes[_newPepe(newGenotype, uint64(_mother), uint64(_father), newGeneration, _pepeReceiver)].canCozyAgain = mother.canCozyAgain; //_pepeReceiver becomes the master of the pepe

        return true;
    }

    /**
     * @dev Internal function to increase the coolDownIndex
     * @param _pepeId The id of the Pepe to update the coolDown of
     */
    function _handleCoolDown(uint256 _pepeId) internal {
        Pepe storage tempPep = pepes[_pepeId];

        // solhint-disable-next-line not-rely-on-time
        tempPep.canCozyAgain = uint64(now + cozyCoolDowns[tempPep.coolDownIndex]);

        if (tempPep.coolDownIndex < 14) {// after every cozy time pepe gets slower
            tempPep.coolDownIndex++;
        }

    }

    /**
     * @dev Set the name of a Pepe. Can only be set once
     * @param _pepeId ID of the pepe to name
     * @param _name The name to assign
     */
    function setPepeName(uint256 _pepeId, bytes32 _name) public stopWhenHalted onlyPepeMaster(_pepeId) returns(bool) {
        require(pepeNames[_pepeId] == 0x0000000000000000000000000000000000000000000000000000000000000000);
        pepeNames[_pepeId] = _name;
        emit PepeNamed(_pepeId);
        return true;
    }

    /**
     * @dev Transfer a Pepe to the auction contract and auction it
     * @param  _pepeId ID of the Pepe to auction
     * @param  _auction Auction contract address
     * @param  _beginPrice Price the auction starts at
     * @param  _endPrice Price the auction ends at
     * @param  _duration How long the auction should run
     */
    // solhint-disable-next-line max-line-length
    function transferAndAuction(uint256 _pepeId, address _auction, uint256 _beginPrice, uint256 _endPrice, uint64 _duration) public stopWhenHalted onlyPepeMaster(_pepeId) {
        _transfer(msg.sender, _auction, _pepeId);//transfer pepe to auction
        AuctionBase auction = AuctionBase(_auction);

        auction.startAuctionDirect(_pepeId, _beginPrice, _endPrice, _duration, msg.sender);
    }

    /**
     * @dev Approve and buy. Used to buy cozyTime in one call
     * @param  _pepeId Pepe to cozy with
     * @param  _auction Address of the auction contract
     * @param  _cozyCandidate Pepe to approve and cozy with
     * @param  _candidateAsFather Use the candidate as father or not
     */
    // solhint-disable-next-line max-line-length
    function approveAndBuy(uint256 _pepeId, address _auction, uint256 _cozyCandidate, bool _candidateAsFather) public stopWhenHalted payable onlyPepeMaster(_cozyCandidate) {
        approved[_cozyCandidate] = _auction;
        // solhint-disable-next-line max-line-length
        CozyTimeAuction(_auction).buyCozy.value(msg.value)(_pepeId, _cozyCandidate, _candidateAsFather, msg.sender); //breeding resets approval
    }

    /**
     * @dev The same as above only pass an extra parameter
     * @param  _pepeId Pepe to cozy with
     * @param  _auction Address of the auction contract
     * @param  _cozyCandidate Pepe to approve and cozy with
     * @param  _candidateAsFather Use the candidate as father or not
     * @param  _affiliate Address to set as affiliate
     */
    // solhint-disable-next-line max-line-length
    function approveAndBuyAffiliated(uint256 _pepeId, address _auction, uint256 _cozyCandidate, bool _candidateAsFather, address _affiliate) public stopWhenHalted payable onlyPepeMaster(_cozyCandidate) {
        approved[_cozyCandidate] = _auction;
        // solhint-disable-next-line max-line-length
        CozyTimeAuction(_auction).buyCozyAffiliated.value(msg.value)(_pepeId, _cozyCandidate, _candidateAsFather, msg.sender, _affiliate); //breeding resets approval
    }

    /**
     * @dev get Pepe information
     * @param  _pepeId ID of the Pepe to get information of
     * @return master
     * @return genotype
     * @return canCozyAgain
     * @return generation
     * @return father
     * @return mother
     * @return pepeName
     * @return coolDownIndex
     */
    // solhint-disable-next-line max-line-length
    function getPepe(uint256 _pepeId) public view returns(address master, uint256[2] genotype, uint64 canCozyAgain, uint64 generation, uint256 father, uint256 mother, bytes32 pepeName, uint8 coolDownIndex) {
        Pepe storage tempPep = pepes[_pepeId];

        master = tempPep.master;
        genotype = tempPep.genotype;
        canCozyAgain = tempPep.canCozyAgain;
        generation = tempPep.generation;
        father = tempPep.father;
        mother = tempPep.mother;
        pepeName = pepeNames[_pepeId];
        coolDownIndex = tempPep.coolDownIndex;
    }

    /**
     * @dev Get the time when a pepe can cozy again
     * @param  _pepeId ID of the pepe
     * @return Time when the pepe can cozy again
     */
    function getCozyAgain(uint256 _pepeId) public view returns(uint64) {
        return pepes[_pepeId].canCozyAgain;
    }

    /**
     *  ERC721 Compatibility
     *
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @dev Get the total number of Pepes
     * @return total Returns the total number of pepes
     */
    function totalSupply() public view returns(uint256 total) {
        total = pepes.length - balances[address(0)];
        return total;
    }

    /**
     * @dev Get the number of pepes owned by an address
     * @param  _owner Address to get the balance from
     * @return balance The number of pepes
     */
    function balanceOf(address _owner) external view returns (uint256 balance) {
        balance = balances[_owner];
    }

    /**
     * @dev Get the owner of a Pepe
     * @param  _tokenId the token to get the owner of
     * @return _owner the owner of the pepe
     */
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = pepes[_tokenId].master;
    }

    /**
     * @dev Get the id of an token by its index
     * @param _owner The address to look up the tokens of
     * @param _index Index to look at
     * @return tokenId the ID of the token of the owner at the specified index
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) public constant returns (uint256 tokenId) {
        //The index must be smaller than the balance,
        // to guarantee that there is no leftover token returned.
        require(_index < balances[_owner]);

        return wallets[_owner][_index];
    }

    /**
     * @dev Private method that ads a token to the wallet
     * @param _owner Address of the owner
     * @param _tokenId Pepe ID to add
     */
    function addToWallet(address _owner, uint256 _tokenId) private {
        uint256[] storage wallet = wallets[_owner];
        uint256 balance = balances[_owner];
        if (balance < wallet.length) {
            wallet[balance] = _tokenId;
        } else {
            wallet.push(_tokenId);
        }
        //increase owner balance
        //overflow is not likely to happen(need very large amount of pepes)
        balances[_owner] += 1;
    }

    /**
     * @dev Remove a token from a address's wallet
     * @param _owner Address of the owner
     * @param _tokenId Token to remove from the wallet
     */
    function removeFromWallet(address _owner, uint256 _tokenId) private {
        uint256[] storage wallet = wallets[_owner];
        uint256 i = 0;
        // solhint-disable-next-line no-empty-blocks
        for (; wallet[i] != _tokenId; i++) {
            // not the pepe we are looking for
        }
        if (wallet[i] == _tokenId) {
            //found it!
            uint256 last = balances[_owner] - 1;
            if (last > 0) {
                //move the last item to this spot, the last will become inaccessible
                wallet[i] = wallet[last];
            }
            //else: no last item to move, the balance is 0, making everything inaccessible.

            //only decrease balance if _tokenId was in the wallet
            balances[_owner] -= 1;
        }
    }

    /**
     * @dev Internal transfer function
     * @param _from Address sending the token
     * @param _to Address to token is send to
     * @param _tokenId ID of the token to send
     */
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        pepes[_tokenId].master = _to;
        approved[_tokenId] = address(0);//reset approved of pepe on every transfer

        //remove the token from the _from wallet
        removeFromWallet(_from, _tokenId);

        //add the token to the _to wallet
        addToWallet(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev transfer a token. Can only be called by the owner of the token
     * @param  _to Addres to send the token to
     * @param  _tokenId ID of the token to send
     */
    // solhint-disable-next-line no-simple-event-func-name
    function transfer(address _to, uint256 _tokenId) public stopWhenHalted
        onlyPepeMaster(_tokenId) //check if msg.sender is the master of this pepe
        returns(bool)
    {
        _transfer(msg.sender, _to, _tokenId);//after master modifier invoke internal transfer
        return true;
    }

    /**
     * @dev Approve a address to send a token
     * @param _to Address to approve
     * @param _tokenId Token to set approval for
     */
    function approve(address _to, uint256 _tokenId) external stopWhenHalted
        onlyPepeMaster(_tokenId)
    {
        approved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Approve or revoke approval an address for al tokens of a user
     * @param _operator Address to (un)approve
     * @param _approved Approving or revoking indicator
     */
    function setApprovalForAll(address _operator, bool _approved) external stopWhenHalted {
        if (_approved) {
            approvedForAll[msg.sender][_operator] = true;
        } else {
            approvedForAll[msg.sender][_operator] = false;
        }
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Get approved address for a token
     * @param _tokenId Token ID to get the approved address for
     * @return The address that is approved for this token
     */
    function getApproved(uint256 _tokenId) external view returns (address) {
        return approved[_tokenId];
    }

    /**
     * @dev Get if an operator is approved for all tokens of that owner
     * @param _owner Owner to check the approval for
     * @param _operator Operator to check approval for
     * @return Boolean indicating if the operator is approved for that owner
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return approvedForAll[_owner][_operator];
    }

    /**
     * @dev Function to signal support for an interface
     * @param interfaceID the ID of the interface to check for
     * @return Boolean indicating support
     */
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        if (interfaceID == 0x80ac58cd || interfaceID == 0x01ffc9a7) { //TODO: add more interfaces the contract supports
            return true;
        }
        return false;
    }

    /**
     * @dev Safe transferFrom function
     * @param _from Address currently owning the token
     * @param _to Address to send token to
     * @param _tokenId ID of the token to send
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external stopWhenHalted {
        _safeTransferFromInternal(_from, _to, _tokenId, "");
    }

    /**
     * @dev Safe transferFrom function with aditional data attribute
     * @param _from Address currently owning the token
     * @param _to Address to send token to
     * @param _tokenId ID of the token to send
     * @param _data Data to pass along call
     */
    // solhint-disable-next-line max-line-length
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external stopWhenHalted {
        _safeTransferFromInternal(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Internal Safe transferFrom function with aditional data attribute
     * @param _from Address currently owning the token
     * @param _to Address to send token to
     * @param _tokenId ID of the token to send
     * @param _data Data to pass along call
     */
    // solhint-disable-next-line max-line-length
    function _safeTransferFromInternal(address _from, address _to, uint256 _tokenId, bytes _data) internal onlyAllowed(_tokenId) {
        require(pepes[_tokenId].master == _from);//check if from is current owner
        require(_to != address(0));//throw on zero address

        _transfer(_from, _to, _tokenId); //transfer token

        if (isContract(_to)) { //check if is contract
            // solhint-disable-next-line max-line-length
            require(ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, _data) == bytes4(keccak256("onERC721Received(address,uint256,bytes)")));
        }
    }

    /**
     * @dev TransferFrom function
     * @param _from Address currently owning the token
     * @param _to Address to send token to
     * @param _tokenId ID of the token to send
     * @return If it was successful
     */
    // solhint-disable-next-line max-line-length
    function transferFrom(address _from, address _to, uint256 _tokenId) public stopWhenHalted onlyAllowed(_tokenId) returns(bool) {
        require(pepes[_tokenId].master == _from);//check if _from is really the master.
        require(_to != address(0));
        _transfer(_from, _to, _tokenId);//handles event, balances and approval reset;
        return true;
    }

    /**
     * @dev Utility method to check if an address is a contract
     * @param _address Address to check
     * @return Boolean indicating if the address is a contract
     */
    function isContract(address _address) internal view returns (bool) {
        uint size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_address) }
        return size > 0;
    }

}
