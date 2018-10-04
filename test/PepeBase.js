var PepeBase = artifacts.require("PepeBase");
var pepeContract;

contract('PepeBase',async function(accounts) {

  it("Owner of the contract should be accounts[0]", async function() {
    pepeContract = await PepeBase.deployed();
    let owner = await pepeContract.owner();
    assert.equal(owner, accounts[0], "Owner should be accounts[0]")
  });

  it("Pepe 0 should be burned", async function() {
    await pepeContract.pepePremine(1, {from: accounts[0]});
    let pepeOwner = await pepeContract.ownerOf(0);
    assert.equal("0x0000000000000000000000000000000000000000", pepeOwner, "Pepe 0 should have been send to 0x00000 address");
  });

  it("Premining from wrong address should fail", async function() {
    let error = false;

    try {
     await pepeContract.pepePremine(10, {from: accounts[1]});
    } catch (e) {
     error = true;
    }

    assert.equal(true, error, "Should have thrown error");

  });

  it("Premining should go well", async function() {
    await pepeContract.pepePremine(10, {from: accounts[0]});
  });

  it("CozyTiming 2 pepes of the same owner should go well", async function() {
    await pepeContract.cozyTime(4, 3, accounts[0], {from: accounts[0]});

    let pepe = await pepeContract.pepes(11);
    assert.equal(pepe[0], accounts[0], "New pepe should have the correct owner");
    assert.equal(pepe[2].toNumber(), 1, "Should be generation 1");
    assert.equal(3, pepe[3].toNumber(), "Pepe 3 should be the father");
    assert.equal(4, pepe[4].toNumber(), "Pepe 4 should be the mother");
    assert.equal(pepe[7].toNumber(), 0, "Cooldown index should be 0");

    let pepeMother = await pepeContract.pepes(4);
    let pepeFather = await pepeContract.pepes(3);
    assert.equal(pepeMother[7], 1, "Cooldown index should be 1");
    assert.equal(pepeFather[7], 1, "Cooldown index should be 1");
  });

  it("Trying to send a Pepe not owned by you it should fail", async function() {
    let error = false;
    try {
      await pepeContract.transfer(accounts[2], 1, {from: accounts[1]});
    } catch(e) {
      error = true;
    }
    assert.equal(error, true, "Should have thrown error");
  });

  it("Sending a Pepe from the right address should go well", async function() {
    await pepeContract.approve(accounts[3], 1);
    await pepeContract.transfer(accounts[2], 1, {from: accounts[0]});

    let owner = await pepeContract.ownerOf(1);
    let approved = await pepeContract.approved(1);

    assert.equal(owner, accounts[2], "The new owner should be accounts[2]");
    assert.equal(approved, "0x0000000000000000000000000000000000000000", "Approval should have been reset");
  });

  it("Doing transferFrom from unapproved address should fail", async function() {
    let error = false;
    try {
      await pepeContract.transferFrom(accounts[2], accounts[1], 1);
    } catch(e) {
      error = true;
    }

    assert.equal(error, true, "Should have thrown error");

  });

  it("Calling approve from non owner should fail", async function() {
    let error = false;

    try {
      await pepeContract.approve(accounts[3], 1);
    } catch(e) {
      error = true;
    }

    assert.equal(error, true, "Should have thrown error");
  });

  it("Doing approve and calling transferFrom should go well", async function() {
    await pepeContract.approve(accounts[0], 1, {from: accounts[2]});
    await pepeContract.transferFrom(accounts[2], accounts[1], 1);

    owner = await pepeContract.ownerOf(1);
    approved = await pepeContract.approved(1);

    assert.equal(owner, accounts[1], "The owner should have changed");
    assert.equal(approved, "0x0000000000000000000000000000000000000000", "approval should be 0x0000");

  });

  it("CozyTiming approved Pepes should go well", async function() {
    await pepeContract.pepePremine(2);

    await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [(3 * 60 * 60) + 1], id: 123});

    let numberOfpepes = await pepeContract.totalSupply();
    numberOfPepes = numberOfpepes.toNumber() - 1;

    await pepeContract.approve(accounts[3], numberOfPepes);
    await pepeContract.approve(accounts[3], numberOfPepes - 1);

    await pepeContract.cozyTime(numberOfPepes, numberOfPepes - 1, accounts[0], {from: accounts[3]});

    let pepe = await pepeContract.pepes(numberOfPepes + 1);

    assert.equal(pepe[0], accounts[0], "Owner of new pepe should be accounts[0]");

  });

  it("Premine should be limited", async function() {
    let premined = await pepeContract.zeroGenPepes();
    premined = premined.toNumber();

    for(var i = 0; i < 100 - premined; i ++){
      await pepeContract.pepePremine(1);
    }

    let error = false;

    try {
      await pepeContract.pepePremine(1);
    } catch (e) {
      error = true;
    }
    assert.equal(error, true, "Should have thrown error");

  });

});
