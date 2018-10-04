let PepeBase = artifacts.require("PepeBase");
let PepeBaseContract;


contract('Usernames', function(accounts) {

  it("Claiming a username should work", async function() {
    PepeBaseContract = await PepeBase.deployed();

    await PepeBaseContract.claimUsername("LOL");

    let username = await PepeBaseContract.addressToUser(accounts[0]);
    username = web3.toAscii(username).replace(new RegExp("\u0000", 'g'), "");

    let address = await PepeBaseContract.userToAddress("LOL");

    assert.equal(address, accounts[0], "Username should refer to accounts[0]")
    assert.equal("LOL", username, "Username should be LOL");
  });

  it("Claiming a username that was already taken should fail", async function() {
    let error = false;

    try {
      await PepeBaseContract.claimUsername("LOL", {from: accounts[1]})
    } catch (e) {
      error = true;
    }

    assert.equal(error, true, "Should have thrown error");

  });

  it("Claiming a new username should work", async function() {
    await PepeBaseContract.claimUsername("LMAO");

    let addressOld = await PepeBaseContract.userToAddress("LOL");
    let addressNew = await PepeBaseContract.userToAddress("LMAO");
    let username = await PepeBaseContract.addressToUser(accounts[0]);
    username = web3.toAscii(username).replace(new RegExp("\u0000", 'g'), "");

    assert.equal(addressOld, "0x0000000000000000000000000000000000000000", "Old username should be free again");
    assert.equal(addressNew, accounts[0], "Username should refer to accounts[0]");
    assert.equal(username, "LMAO", "Username should be LMAO");

  });

  it("Claiming a previously used username should work", async function() {
    await PepeBaseContract.claimUsername("LOL", {from : accounts[1]});

    let address = await PepeBaseContract.userToAddress("LOL");
    let username = await PepeBaseContract.addressToUser(accounts[1]);
    username = web3.toAscii(username).replace(new RegExp("\u0000", 'g'), "");

    assert.equal(address, accounts[1], "Username should now be owned by accounts[1]");
    assert.equal(username, "LOL", "Username of accounts[1] should be LOL");

  });


});
