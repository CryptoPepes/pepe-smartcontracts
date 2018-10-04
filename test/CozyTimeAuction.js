var CozyTimeAuction = artifacts.require("CozyTimeAuction");
var PepeBase = artifacts.require("PepeBase");

contract('CozyTimeAuction', function(accounts) {

  var cozyTimeAuctionInstance;
  var pepeBaseInstance;

  it("Calling startAuction while pepe cannot cozy again should fail", async function() {
    pepeBaseInstance = await PepeBase.deployed();
    cozyTimeAuctionInstance = await CozyTimeAuction.deployed();

    await pepeBaseInstance.pepePremine(11);
    await pepeBaseInstance.cozyTime(1, 2, accounts[0]);
    await pepeBaseInstance.approve(cozyTimeAuctionInstance.address, 1);

    error = false;

    try {
      // 3 hour auction
      await cozyTimeAuctionInstance.startAuction(1, web3.toWei(1, "ether"), web3.toWei(2, "ether"), 3 * 60 * 60);
    } catch(e) {
      error = true;
    }

    assert.equal(error, true, "Should have thrown error");
  });

  it("Calling startAuction when pepe can cozy again should go well", async function() {
    await pepeBaseInstance.approve(cozyTimeAuctionInstance.address, 3);
    await cozyTimeAuctionInstance.startAuction(3, web3.toWei(1, "ether"), web3.toWei(2, "ether"), 3 * 60 * 60);

    let auction = await cozyTimeAuctionInstance.auctions(3);

    assert.equal(auction[0], accounts[0], "Seller should be accounts[0]");
    assert.equal(auction[1].toString(), "3", "It should be pepe 3 for sale");
    assert.notEqual(auction[2].toString(), "0", "Start should be set");
    assert.notEqual(auction[3].toString(), "0", "End should be set");
    assert(auction[3].minus(auction[2]).equals(3 * 60 * 60), "Duration should be 3 hours");
    assert.equal(auction[4], web3.toWei(1, "ether"), "Start price should be 1 ether");
    assert.equal(auction[5], web3.toWei(2, "ether"), "End price should be 2 ether");
  });

  it("Buying cozy should work", async function() {
    await pepeBaseInstance.transfer(accounts[1], 4);
    //await pepeBaseInstance.approve(cozyTimeAuctionInstance.address, 4, {from: accounts[1]});
    //await pepeBaseInstance.buyCozy(3, 4, true, {from: accounts[1], value: web3.toWei(2, "ether")});
    await pepeBaseInstance.approveAndBuy(3, cozyTimeAuctionInstance.address, 4, false, {from: accounts[1], value: web3.toWei(2, "ether")});
    let newPepeOwner = await pepeBaseInstance.ownerOf(12);
    let coziedPepeOwner = await pepeBaseInstance.ownerOf(3);

    assert.equal(newPepeOwner, accounts[1], "Owner of new pepe should be accounts[1]");
    assert.equal(coziedPepeOwner, accounts[0], "Pepe should be back at the seller");
  });

  it("Calling startAuctionDirect while pepe cannot cozy again should fail", async function() {
     await pepeBaseInstance.pepePremine(3);

     let pepe1 = (await pepeBaseInstance.totalSupply()) - 1;
     let pepe2 =  await pepeBaseInstance.totalSupply();

     pepeBaseInstance.cozyTime(pepe1, pepe2, accounts[0]);

     let error = false;

     try {
       // 3 hour auction
       await pepeBaseInstance.transferAndAuction(pepe1, cozyTimeAuctionInstance.address, web3.toWei(1, "ether"), web3.toWei(2, "ether"), 3 * 60 * 60);
     } catch(e) {
       error = true;
     }

     assert.equal(error, true, "Should have thrown error");
  });

  it("Calling startAuctionDirect while pepe can cozy again should go well", async function() {
      await pepeBaseInstance.pepePremine(1);

      let pepe = await pepeBaseInstance.totalSupply();

      await pepeBaseInstance.transferAndAuction(pepe, cozyTimeAuctionInstance.address, web3.toWei(1, "ether"), web3.toWei(2, "ether"), 3 * 60 * 60);

      let auction = await cozyTimeAuctionInstance.auctions(pepe);

      assert.equal(auction[0], accounts[0], "Seller should be accounts[0]");
      assert.equal(auction[1].toString(), pepe.toString(), "It should be pepe 3 for sale");
      assert.notEqual(auction[2].toString(), "0", "Start should be set");
      assert.notEqual(auction[3].toString(), "0", "End should be set");
      assert(auction[3].minus(auction[2]).equals(3 * 60 * 60), "Duration should be 3 hours");
      assert.equal(auction[4], web3.toWei(1, "ether"), "Start price should be 1 ether");
      assert.equal(auction[5], web3.toWei(2, "ether"), "End price should be 2 ether");
  });
});
