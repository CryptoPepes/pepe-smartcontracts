var Web3Utils = require('web3-utils');

var BN = Web3Utils.BN;

var Mining = artifacts.require("Mining");
var PepeGrinder = artifacts.require("PepeGrinder");
var PepeBase = artifacts.require("PepeBase");
var PepToken = artifacts.require("PepToken");

var pepeBaseInstance, miningInstance, pepeGrinderInstance, pepTokenInstance;

contract('Mining', function(accounts) {


  it("Mining 32 blocks should work", async function() {
      pepeBaseInstance = await PepeBase.deployed();
      miningInstance = await Mining.deployed();
      pepeGrinderInstance = await PepeGrinder.deployed();
      pepTokenInstance = await PepToken.deployed();

      await minePepes(32, accounts[2]);

      let balance = await pepTokenInstance.balanceOf(accounts[2]);
      let pepeBalance = await pepeBaseInstance.balanceOf(accounts[2]);
      assert.equal(Web3Utils.toBN(balance), web3.toWei(2500 * 32),  "Balance should be 2500 * 32");
      assert.equal(pepeBalance.toNumber(), 2, "Pepe balance should be 2");
  });

  it("dusting should work", async function() {
      await pepeGrinderInstance.setDusting({from: accounts[2]});

      await minePepes(16, accounts[2]);

      let dustBalance = await pepeGrinderInstance.balanceOf(accounts[2]);
      let grinderBalance = await pepeBaseInstance.balanceOf(PepeGrinder.address);

      assert.equal(dustBalance, web3.toWei(100), "Dust balance should be 100");
      assert.equal(1, grinderBalance.toNumber(), "The grinder should now hold 1 CPEP");
  });

  it("Getting a pepe from dust should work", async function() {
      await pepeGrinderInstance.transfer(accounts[1], web3.toWei(100), {from: accounts[2]});
      await pepeGrinderInstance.claimPepe({from: accounts[1]});

      let dustBalance = await pepeGrinderInstance.balanceOf(accounts[1]);
      let pepeBalance = await pepeBaseInstance.balanceOf(accounts[1]);
      let grinderBalance = await pepeBaseInstance.balanceOf(PepeGrinder.address);

      assert.equal(dustBalance, web3.toWei(0), "Dust balance should be 0");
      assert.equal(0, grinderBalance.toNumber(), "The grinder should now hold 0 CPEP");
      assert.equal(1, pepeBalance.toNumber(), "This account should now hold 1 Pepe");
  });

  it("Claiming a pepe without enough dust should fail", async function() {
      await minePepes(16, accounts[2]);
      await pepeGrinderInstance.transfer(accounts[1], web3.toWei(1), {from: accounts[2]});
      let error = false;
      try {
        await pepeGrinderInstance.claimPepe({from: accounts[2]});
      } catch (e) {
        error = true;
      }

      let dustBalance = await pepeGrinderInstance.balanceOf(accounts[2]);
      let grinderBalance = await pepeBaseInstance.balanceOf(PepeGrinder.address);

      assert.equal(grinderBalance.toNumber(), 1, "The grinder should now hold 1 CPEP");
      assert.equal(error, true, "should have thrown error");
      assert.equal(dustBalance, web3.toWei(99), "Dust balance should be 99");
  });


});

async function minePepes(amountOfPepes, account) {
  for(var i = 0; i < amountOfPepes; i ++) {
    let challengeNumber  = await miningInstance.getChallengeNumber();
    let difficulty = await miningInstance.getMiningTarget();

    difficulty = Web3Utils.toBN(difficulty);
    var counter = 0;
    while(true) {
        //console.log(difficulty);

        var bytesNonce = Web3Utils.randomHex(32);
        var nonce = Web3Utils.toBN(bytesNonce);
        //console.log("nonce " + nonce.toString());
        var digest = Web3Utils.soliditySha3({t: 'bytes32', v: challengeNumber},{t: 'address', v: account},{t: 'uint256', v: bytesNonce});
        var digestBytes32 = Web3Utils.hexToBytes(digest)
        var digestBigNumber = Web3Utils.toBN(digest)

        //console.log("digest " + digestBigNumber.toString());
        //console.log("difficulty " + difficulty.toString());
        if(digestBigNumber.lt(difficulty)) {
          //console.log("solution #" + i + " found after " + counter + " hashes");
          await miningInstance.mint(bytesNonce, digest, {from: account});
          break;
        }

        counter ++;
    }
  }
}
