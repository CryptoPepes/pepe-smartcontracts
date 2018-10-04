// solhint-disable-next-line
pragma solidity ^0.4.4;

// solhint-disable max-line-length

import "./PepeBase.sol";
import "./PepToken.sol";
import "./PepeGrinder.sol";
import "./Beneficiary.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Math/ExtendedMath.sol";

// solhint-disable-next-line
contract Mining is Beneficiary {

    using SafeMath for uint;
    using ExtendedMath for uint;

    uint public latestDifficultyPeriodStarted = block.number;
    uint public epochCount = 0;//number of 'blocks' mined
    uint public constant MAX_EPOCH_COUNT = 16000;
    uint public baseMiningReward = 2500 ether;
    uint public blocksPerReadjustment = 20;
    uint public tokensMinted;

    // solhint-disable var-name-mixedcase
    uint public _MINIMUM_TARGET = 2**16;
    uint public _MAXIMUM_TARGET = 2**250; //Testing setting!
    //uint public _MAXIMUM_TARGET = 2**230; //SHOULD MAKE THIS HARDER IN PRODUCTION
    bytes32 public challengeNumber;
    uint public difficulty;
    uint public MINING_RATE_FACTOR = 31; //mint the token 31 times less often than ether
    //difficulty adjustment parameters- be careful modifying these
    uint public MAX_ADJUSTMENT_PERCENT = 100;
    uint public TARGET_DIVISOR = 2000;
    uint public QUOTIENT_LIMIT = TARGET_DIVISOR.div(2);
    mapping(bytes32 => bytes32) public solutionForChallenge;

    Statistics public statistics;

    PepeBase public pepeContract;
    PepToken public pepToken;
    PepeGrinder public pepeGrinder;

    uint256 public miningStart;//timestamp when mining starts

    event Mint(address indexed from, uint rewardAmount, uint epochCount, bytes32 newChallengeNumber);

    // track read only minting statistics
    struct Statistics {
        address lastRewardTo;
        uint lastRewardAmount;
        uint lastRewardEthBlockNumber;
        uint lastRewardTimestamp;
    }

    constructor(address _pepeContract, address _pepToken, address _pepeGrinder, uint256 _miningStart) public {
        pepeContract = PepeBase(_pepeContract);
        pepToken = PepToken(_pepToken);
        pepeGrinder = PepeGrinder(_pepeGrinder);
        difficulty = _MAXIMUM_TARGET;
        miningStart = _miningStart;
    }

    ///TEMP METHOD FOR TESTING!!!!
    function setDifficulty(uint256 _difficulty) public {
        difficulty = _difficulty;
    }

    /**
     * Mint a new pepe if noce is correct
     * @param nonce The nonce to submit
     * @param challengeDigest The resulting digest
     * @return success Boolean indicating if mint was successful
     */
    // solhint-disable-next-line
    function mint(uint256 nonce, bytes32 challengeDigest) public returns (bool success) {
        require(epochCount < MAX_EPOCH_COUNT);//max 16k blocks
        // solhint-disable-next-line not-rely-on-time
        require(now > miningStart);
        // perform the hash function validation
        _hash(nonce, challengeDigest);

        // calculate the current reward
        uint rewardAmount = _reward(nonce);

        // increment the minted tokens amount
        tokensMinted += rewardAmount;

        epochCount += 1;
        challengeNumber = blockhash(block.number - 1);

        _adjustDifficulty();

        //populate read only diagnostics data
        // solhint-disable-next-line not-rely-on-time
        statistics = Statistics(msg.sender, rewardAmount, block.number, now);

        // send Mint event indicating a successful implementation
        emit Mint(msg.sender, rewardAmount, epochCount, challengeNumber);

        if (epochCount == MAX_EPOCH_COUNT) { //destroy this smart contract on the latest block
            selfdestruct(msg.sender);
        }

        return true;
    }

    /**
     * Get the current challengeNumber
     * @return bytes32 challengeNumber
     */
    function getChallengeNumber() public constant returns (bytes32) {
        return challengeNumber;
    }

    /**
     * Get the current mining difficulty
     * @return the current difficulty
     */
    function getMiningDifficulty() public constant returns (uint) {
        return _MAXIMUM_TARGET.div(difficulty);
    }

    /**
     * Get the mining target
     * @return The current mining target
     */
    function getMiningTarget() public constant returns (uint256) {
        return difficulty;
    }

    /**
     * Get the mining reward
     * @return The current mining reward. Always 2500PEP
     */
    function getMiningReward() public constant returns (uint256) {
        return baseMiningReward;
    }

    /**
     * Helper method to check a nonce
     * @param nonce The nonce to check
     * @param challengeDigest the digest to check
     * @param challengeNumber to check
     * @return digesttest The resulting digest
     */
    // solhint-disable-next-line
    function getMintDigest(uint256 nonce, bytes32 challengeDigest, bytes32 challengeNumber) public view returns (bytes32 digesttest) {
        bytes32 digest = keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));
        return digest;
    }

    /**
     * Helper method to check if a nonce meets the difficulty
     * @param nonce The nonce to check
     * @param challengeDigest the digest to check
     * @param challengeNumber the challenge number to check
     * @param testTarget the difficulty to check
     * @return success Boolean indicating success
     */
    function checkMintSolution(uint256 nonce, bytes32 challengeDigest, bytes32 challengeNumber, uint testTarget) public view returns (bool success) {
        bytes32 digest = keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));
        if (uint256(digest) > testTarget) revert();
        return (digest == challengeDigest);
    }

    /**
     * Internal function to check a hash
     * @param nonce The nonce to check
     * @param challengeDigest it should create
     * @return digest The digest created
     */
    function _hash(uint256 nonce, bytes32 challengeDigest) internal returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));
        //the challenge digest must match the expected
        if (digest != challengeDigest) revert();
        //the digest must be smaller than the target
        if (uint256(digest) > difficulty) revert();
        //only allow one reward for each challenge
        bytes32 solution = solutionForChallenge[challengeNumber];
        solutionForChallenge[challengeNumber] = digest;
        if (solution != 0x0) revert();  //prevent the same answer from awarding twice
    }

    /**
     * Reward a miner Pep tokens
     * @param nonce Nonce to use as seed for Pepe dna creation
     * @return The amount of PEP tokens rewarded
     */
    function _reward(uint256 nonce) internal returns (uint) {
        uint reward_amount = getMiningReward();
        pepToken.transfer(msg.sender, reward_amount);

        if (epochCount % 16 == 0) { //every 16th block reward a pepe
            if (pepeGrinder.dusting(msg.sender)) { //if miner is pool mining send it through the grinder
                uint256 newPepe = pepeContract.minePepe(nonce, address(pepeGrinder));
                pepeGrinder.dustPepe(newPepe, msg.sender);
            } else {
                pepeContract.minePepe(nonce, msg.sender);
            }
            //every 16th block send part of the block reward
            pepToken.transfer(beneficiary, reward_amount);
        }

        return reward_amount;
    }

    /**
     * Internal method to readjust difficulty
     * @return The new difficulty
     */
    function _adjustDifficulty() internal returns (uint) {
        //every so often, readjust difficulty. Dont readjust when deploying
        if (epochCount % blocksPerReadjustment != 0) {
            return difficulty;
        }

        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        //assume 360 ethereum blocks per hour
        //we want miners to spend 8 minutes to mine each 'block', about 31 ethereum blocks = one CryptoPepes block
        uint epochsMined = blocksPerReadjustment;
        uint targetEthBlocksPerDiffPeriod = epochsMined * MINING_RATE_FACTOR;
        //if there were less eth blocks passed in time than expected
        if (ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod) {
            uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(MAX_ADJUSTMENT_PERCENT)).div(ethBlocksSinceLastDifficultyPeriod);
            uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(QUOTIENT_LIMIT);
            // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.
            //make it harder
            difficulty = difficulty.sub(difficulty.div(TARGET_DIVISOR).mul(excess_block_pct_extra));   //by up to 50 %
        } else {
            uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(MAX_ADJUSTMENT_PERCENT)).div(targetEthBlocksPerDiffPeriod);
            uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(QUOTIENT_LIMIT); //always between 0 and 1000
            //make it easier
            difficulty = difficulty.add(difficulty.div(TARGET_DIVISOR).mul(shortage_block_pct_extra));   //by up to 50 %
        }
        latestDifficultyPeriodStarted = block.number;
        if (difficulty < _MINIMUM_TARGET) { //very dificult
            difficulty = _MINIMUM_TARGET;
        }
        if (difficulty > _MAXIMUM_TARGET) { //very easy
            difficulty = _MAXIMUM_TARGET;
        }

        return difficulty;
    }

}
