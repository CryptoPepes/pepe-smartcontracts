var PepeBase = artifacts.require("PepeBase");
var CozyAuction = artifacts.require("CozyTimeAuction");
var Affiliate = artifacts.require("Affiliate");
var pepeBaseInstance;
var auctionInstance;
var affiliateInstance;

var haltDuration = 60 * 60 * 24 * 7;

contract('Haltable - Basic Halting', function(accounts) {
  it("Halting contract from non owner should fail", async function() {
      pepeBaseInstance = await PepeBase.deployed();

      let error = false;
      try {
        await pepeBaseInstance.halt(60 * 60 * 24 * 7, {from: accounts[1]});
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "Should have thrown error");
  });

  it("Halting for to long should fail", async function() {
      let error = false;
      try {
        await pepeBaseInstance.halt(haltDuration * 8 + 100);
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "Should have thrown error");
  });

  it("Halting from owner and a right time duration should go well", async function(){
      await pepeBaseInstance.halt(haltDuration);

      let haltTime = await pepeBaseInstance.haltTime();
      let halted = await pepeBaseInstance.halted();
      let contractHaltDuration = await pepeBaseInstance.haltDuration();

      assert.notEqual(haltTime, 0, "HaltTime should not be 0");
      assert.equal(halted, true, "Should now be halted");
      assert.equal(contractHaltDuration, haltDuration, "Haltduration is wrong");
  });

  it("Unhalting to soon from non owner should fail", async function() {
      let error = false;

      try {
        await pepeBaseInstance.unhalt({from: accounts[1]});
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "Should have thrown error");
  });

  it("Unhalting from owner should work at any time", async function() {
      await pepeBaseInstance.unhalt();

      let halted = await pepeBaseInstance.halted();

      assert.equal(halted, false, "contract should not be halted anymore");
  });

  it("Halting the contract twice should fail", async function() {
      let error = false;
      try {
        await pepeBaseInstance.halt();
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "Should have thrown error");
  });

});

contract('Haltable - Halt and unhalt after time passed by', function(accounts) {
    it("Unhalting after time has passed should work", async function(){
      pepeBaseInstance = await PepeBase.deployed();

      await pepeBaseInstance.halt(haltDuration);
      let haltedBefore = await pepeBaseInstance.halted();
      //increase time
      await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [haltDuration + 1], id: 123});

      await pepeBaseInstance.unhalt({from: accounts[1]});
      let haltedAfter = await pepeBaseInstance.halted();

      assert.equal(true, haltedBefore, "Should have been halted");
      assert.equal(false, haltedAfter, "Should be unhalted now");
    });
});

contract('Haltable - Check methods if they halt correctly', function(accounts) {
    it("Mine pepe should fail when halted", async function() {
      pepeBaseInstance = await PepeBase.new(); //instance seperate from standard deploy
      await pepeBaseInstance.setMiner(accounts[2]);
      await pepeBaseInstance.halt(haltDuration);

      let error = false;

      try {
        await pepeBaseInstance.minePepe(100, accounts[1], {from : accounts[2]});
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("Pepe premine should fail when halted", async function() {
      let error = false;

      try {
        await pepeBaseInstance.pepePremine(1);
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("CozyTime should fail when halted", async function() {
      pepeBaseInstance = await PepeBase.new(); //need new instance with actual pepes
      await pepeBaseInstance.pepePremine(10);
      await pepeBaseInstance.halt(haltDuration);

      let error = false;
      try {
        await pepeBaseInstance.cozyTime(1, 2, accounts[3]);
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("SetPepeName should fail when halted", async function() {
      let error = false;
      try {
        await pepeBaseInstance.setPepeName(3, web3.toAscii("hello").replace(new RegExp("\u0000", 'g'), ""));
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("TransferAndAuction should fail when halted", async function() {
      //need auction instance for this test
      auctionInstance = await CozyAuction.new(pepeBaseInstance.address, Affiliate.address);
      //await pepeBaseInstance.unhalt();
      let error = false;
      try {
        await pepeBaseInstance.transferAndAuction(4, auctionInstance.address, web3.toWei(1, "ether"), web3.toWei(1, "ether"), 60 * 60);
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("ApproveAndBuy should fail when halted", async function() {
      //need new pepeBaseInstance and auction instance for this;
      pepeBaseInstance = await PepeBase.new();
      auctionInstance = await CozyAuction.new(pepeBaseInstance.address, Affiliate.address);
      await pepeBaseInstance.pepePremine(10);
      await pepeBaseInstance.transferAndAuction(4, auctionInstance.address, web3.toWei(1, "ether"), web3.toWei(1, "ether"), 60 * 60);
      await pepeBaseInstance.transfer(accounts[1], 1);

      await pepeBaseInstance.halt(haltDuration);

      let error = false;

      try {
        await pepeBaseInstance.approveAndBuy(4, auctionInstance.address, 1, true, {from: accounts[1], value: web3.toWei(2, "ether")});
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("ApproveAndBuyAffiliated should fail when halted", async function() {
      //need new pepeBaseInstance and auction instance for this;
      pepeBaseInstance = await PepeBase.new();
      auctionInstance = await CozyAuction.new(pepeBaseInstance.address, Affiliate.address);
      affiliateInstance = await Affiliate.deployed();

      await affiliateInstance.setAffiliateSetter(auctionInstance.address);

      await pepeBaseInstance.pepePremine(10);
      await pepeBaseInstance.transferAndAuction(4, auctionInstance.address, web3.toWei(1, "ether"), web3.toWei(1, "ether"), 60 * 60);
      await pepeBaseInstance.transfer(accounts[1], 1);

      await pepeBaseInstance.halt(haltDuration);

      let error = false;

      try {
        await pepeBaseInstance.approveAndBuyAffiliated(4, auctionInstance.address, 1, true, accounts[3] , {from: accounts[1], value: web3.toWei(2, "ether")});
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("Transfer should fail when halted", async function() {
      let error = false;
      try {
        await pepeBaseInstance.transfer(accounts[1], 2);
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("Approve should fail when halted", async function() {
      let error = false;
      try {
        await pepeBaseInstance.approve(account[1], 3);
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("setApprovalForAll should fail when halted", async function() {
      let error = false;
      try {
        await pepeBaseInstance.setApprovalForAll(accounts[2], true);
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("safeTransferFrom without data should fail when halted", async function () {
      let error = false;
      try {
        await pepeBaseInstance.safeTransferFrom(accounts[0], accounts[1], 5);
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("safeTransferFrom with data should fail when halted", async function() {
      let error = false;
      try {
        await pepeBaseInstance.safeTransferFrom(accounts[0], accounts[1], 6, "0x000000000000000000000000000000000000000000000000000000000000006f");
      } catch (e) {
        error = true;
      }

      assert.equal(true, error, "should have thrown error");
    });

    it("transferFrom should fail when halted", async function() {
      let error = false;
      try {
        await pepeBaseInstance.transferFrom(accounts[0], accounts[1], 7);
      } catch (e) {
        error = true;
      }
      assert.equal(true, error, "should have thrown error");
    });

    it("Methods should work again after unlock", async function() {
      await pepeBaseInstance.unhalt();
      await pepeBaseInstance.transfer(accounts[1], 8);

      let pepeOwner = await pepeBaseInstance.ownerOf(8);

      assert.equal(pepeOwner, accounts[1]);
    });

});
