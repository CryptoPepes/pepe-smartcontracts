let PepeAuctionSale = artifacts.require("PepeAuctionSale");
let PepeBase = artifacts.require("PepeBase");
let pepeAuctionSaleContract;
let pepeBaseContract;

contract('PepeAuctionSale', function(accounts) {

  it("Owner of auction sale should be correct", async function() {
    PepeAuctionSaleContract = await PepeAuctionSale.deployed();
    PepeBaseContract = await PepeBase.deployed();
    owner = await PepeAuctionSaleContract.owner();
    assert.equal(owner, accounts[0], "Owner should be accounts[0]");
  });

  it("Changing fee from non owner should fail", async function() {
    let error = false;
    try {
      await PepeAuctionSaleContract.changeFee(1, {from: accounts[1]});
    } catch(e) {
      error = true;
    }

    assert.equal(error, true, "Should have thrown error");
  });

  it("Raising fee should fail", async function() {
    let error = false;
    try {
      await PepeAuctionSaleContract.changeFee(38500)
    } catch(e) {
      error = true;
    }

    assert.equal(error, true, "Should have thrown error");
  });

  it("Lowering fee should work", async function() {
    await PepeAuctionSaleContract.changeFee(37000);

    let fee = await PepeAuctionSaleContract.fee();

    assert.equal(fee.toNumber(), 37000, "Fee should be 37000");

  });

  it("Adding a pepe for sale when contract is not allowed should fail", async function() {
    await PepeBaseContract.pepePremine(10);
    let error = false;

    try{
      await PepeAuctionSaleContract.startAuction(1, web3.toWei(1, "ether"), web3.toWei(2, "ether"), 3 * 60 * 60);
    } catch (e) {
      error = true;
    }

    assert.equal(error, true, "Should have thrown error");

  });

  it("Putting a pepe for sale when approved should go well", async function() {
    await PepeBaseContract.approve(PepeAuctionSaleContract.address, 1);
    await PepeAuctionSaleContract.startAuction(1, web3.toWei(1, "ether"), web3.toWei(2, "ether"), 3 * 60 * 60);

    let pepeOwner = await PepeBaseContract.ownerOf(1);
    assert.equal(pepeOwner, PepeAuctionSaleContract.address, "Pepe should now be owned by the auction contract");

    let auction = await PepeAuctionSaleContract.auctions(1);

    assert.equal(auction[0], accounts[0], "Seller should be accounts[0]");
    assert.equal(auction[1].toString(), "1", "It should be pepe 1 for sale");
    assert.notEqual(auction[2].toString(), "0", "Start should be set");
    assert.notEqual(auction[3].toString(), "0", "End should be set");
    assert(auction[3].minus(auction[2]).equals(3 * 60 * 60), "Duration should be 3 hours");
    assert.equal(auction[4], web3.toWei(1, "ether"), "Start price should be 1 ether");
    assert.equal(auction[5], web3.toWei(2, "ether"), "End price should be 2 ether");

  });

  it("Buying a pepe when not sending enough eth should fail", async function() {
    error = false;
    try {
      await PepeAuctionSaleContract.buyPepe(1, {from : accounts[0], value: web3.toWei(0.5, "ether")});
    } catch (e) {
      error = true;
    }
    assert.equal(error, true, "Must throw error");
  });

  it("Buying a pepe when sending enough ether should go well", async function(){
    await PepeAuctionSaleContract.buyPepe(1, {from : accounts[1], value: web3.toWei(1.5, "ether")});
    let pepeOwner = await PepeBaseContract.ownerOf(1);
    assert.equal(pepeOwner, accounts[1], "Pepe should now be owned by new owner");
  });

  it("Buying a non existent auction should fail", async function() {
    let error = false;
    try{
      await PepeAuctionSaleContract.buyPepe(1, {from: accounts[0], value: web3.toWei(10, "ether")});
    } catch(e) {
      error = true;
    }
    assert.equal(error, true, "Should have thrown error");
  });

  it("Buying a auction that has passed should fail", async function() {
    await PepeBaseContract.approve(PepeAuctionSaleContract.address, 1, {from: accounts[1]});
    await PepeAuctionSaleContract.startAuction(1, web3.toWei(1, "ether"), web3.toWei(2, "ether"), 3 * 60 * 60, {from : accounts[1] });

    await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [(3 * 60 * 60) + 1], id: 123});

    let error = false;

    try {
      await  pepeAuctionSaleContract.buyPepe(1, {from : accounts[0], value: web3.toWei(4, "ether")});
    } catch (e) {
      error = true;
    }
    assert.equal(error, true, "Should have thrown error");
  });

  it("Saving a pepe from a passed auction should work", async function() {
    await PepeAuctionSaleContract.savePepe(1);
    let owner = await PepeBaseContract.ownerOf(1);
    assert.equal(owner, accounts[1], "should be owned by accounts[1]");
  });

  it("Selling a pepe directly from the PepeBase contract should work", async function() {
    PepeBaseContract.transferAndAuction(9, PepeAuctionSaleContract.address, web3.toWei(1, "ether"), web3.toWei(2, "ether"), 3 * 60 * 60, {from: accounts[0]});
    let owner = await PepeBaseContract.ownerOf(9);

    let auction = await PepeAuctionSaleContract.auctions(9);

    assert.equal(auction[0], accounts[0], "Seller should be accounts[0]");
    assert.equal(auction[1].toString(), "9", "It should be pepe 9 for sale");
    assert.notEqual(auction[2].toString(), "0", "Start should be set");
    assert.notEqual(auction[3].toString(), "0", "End should be set");
    assert(auction[3].minus(auction[2]).equals(3 * 60 * 60), "Duration should be 3 hours");
    assert.equal(auction[4], web3.toWei(1, "ether"), "Start price should be 1 ether");
    assert.equal(auction[5], web3.toWei(2, "ether"), "End price should be 2 ether");


    assert.equal(owner, PepeAuctionSale.address);
  });

  it("Saving a Pepe from a running auction should throw", async function() {

    await PepeBaseContract.approve(PepeAuctionSaleContract.address, 1, {from: accounts[1]});
    await PepeAuctionSaleContract.startAuction(1, web3.toWei(1, "ether"), web3.toWei(2, "ether"), 3 * 60 * 60, {from : accounts[1]});

    let error = false;

    try {
      await pepeAuctionSaleContract.savePepe(1);
    } catch (e) {
      error = true;
    }

    assert.equal(error, true, "Should have thrown error");

  });

});
