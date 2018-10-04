let PepeBase = artifacts.require("PepeBase");
let pepeContract;

module.exports = async function(callback) {

  pepeContract = await PepeBase.deployed();

  let zeroGenPepes = await pepeContract.zeroGenPepes();
  let maxPremine = 100;

  for(var i = zeroGenPepes.toNumber(); i < maxPremine; i += 10){
    await pepeContract.pepePremine(10);
    console.log("Premined: " + (i + 10) + " Pepes");

    console.log(await pepeContract.totalSupply());
  }

  console.log("Premine Done!");
  callback(undefined);
}
