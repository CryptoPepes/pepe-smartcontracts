let PepeBase = artifacts.require("PepeBase");
let pepeContract;


module.exports = async function(callback) {
  pepeContract = await PepeBase.deployed();
  accounts = ["0x0FfE13E4304D8c80cBe689f49942Bd15b4371e3c"];

  while(true) {
    balance = await pepeContract.balanceOf(accounts[0]);

    console.log("balance", balance.toString());
    try {
      pep1 = await pepeContract.tokenOfOwnerByIndex(accounts[0], getRandomInt(0, balance));
    } catch (e) {
    }

    try {
      pep2 = await pepeContract.tokenOfOwnerByIndex(accounts[0], getRandomInt(0, balance));
    } catch (e) {

    }

    console.log("breeding", pep1.toString(), "with", pep2.toString());

    try {
      await pepeContract.cozyTime(pep1, pep2, accounts[0]);
    } catch (e) {
      console.log("could not breed");
    }
  }

  callback(undefined);
}

/**
 * Returns a random integer between min (inclusive) and max (inclusive)
 * Using Math.round() will give you a non-uniform distribution!
 */
function getRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}
