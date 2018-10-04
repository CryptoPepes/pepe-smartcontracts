var RevenueSplit = artifacts.require("RevenueSplit");
var revenueSplitInstance;

contract("RevenueSplit", function(accounts) {
  it("The owner should be accounts[0]", async function() {
    revenueSplitInstance = await RevenueSplit.deployed();
    let owner = await revenueSplitInstance.owner();
    assert.equal(owner, accounts[0]);
  });

  it("Adding a beneficiary from a non owner should fail", async function() {
    error = false;
    try{
      await revenueSplitInstance.addBeneficiary(accounts[1], {from: accounts[1]});
    } catch(e) {
      error = true;
    }
    assert.equal(true, error, "Should have thrown error");
  });

  it("Adding a beneficiary from the owner address should work", async function() {
    await revenueSplitInstance.addBeneficiary(accounts[1] ,{from: accounts[0]});
    let beneficiary = await revenueSplitInstance.beneficiaries(0);

    assert.equal(beneficiary, accounts[1], "New beneficiary should be accounts[1]");
  });

  it("Removing a beneficiary from a non owner should fail", async function() {
    error = false;
    try {
      await revenueSplitInstance.removeBeneficiary(0, {from: accounts[1]});
    } catch(e) {
      error = true;
    }
    assert.equal(true, error, "Should throw error");
  });

  it("Removing a beneficiary should work", async function() {
    await revenueSplitInstance.addBeneficiary(accounts[0] ,{from: accounts[0]});
    await revenueSplitInstance.addBeneficiary(accounts[2] ,{from: accounts[0]});
    await revenueSplitInstance.addBeneficiary(accounts[3] ,{from: accounts[0]});
    await revenueSplitInstance.addBeneficiary(accounts[4] ,{from: accounts[0]}); //first add some more before removing
    await revenueSplitInstance.removeBeneficiary(1, {from: accounts[0]});

    let beneficiaries = await revenueSplitInstance.getBeneficiaries();

    assert.equal(beneficiaries.length, 4, "There should be 4 beneficiaries");
    assert.equal(beneficiaries[1], accounts[4], "Accounts[4] should be in the place of the removed one");

    let found = false;

    for(let i = 0; i < beneficiaries.length; i ++){
      if(accounts[0] == beneficiaries[i]){
        found = true;
      }
    }

    assert.equal(false, found, "Accounts[0] should no longer be in there");
  });


});
