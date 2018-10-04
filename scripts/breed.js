let PepeBase = artifacts.require("PepeBase");
let pepeContract;

module.exports = async function(callback) {

  pepeContract = await PepeBase.deployed();

  let gen1s = 0;
  let gen2s = 0;
  let gen3s = 0;

  for(var i = 1; i < 100; i +=2) {
    console.log("CozyTiming " + i + " and " + (i + 1));
    await pepeContract.cozyTime(i, i + 1, "0x627306090abaB3A6e1400e9345bC60c78a8BEf57");
    gen1s ++;
  }
  console.log("Cozy timed gen0s making gen1s");
  await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [3600], id: 123}); //increase time

  for(var ii = 101; ii < 149; ii += 2) {
    console.log("CozyTiming " + ii + " and " + (ii + 1));
    await pepeContract.cozyTime(ii, ii + 1, "0x627306090abaB3A6e1400e9345bC60c78a8BEf57");
    gen2s ++;
  }
  console.log("Cozy timed gen1s making gen2s");
  await web3.currentProvider.send({jsonrpc: "2.0", method: "evm_increaseTime", params: [3600], id: 123}); //increase time

  for(var n = 150; n < 170; n +=2) {
    console.log("CozyTiming " + n + " and " + (n + 1));
    await pepeContract.cozyTime(n, n + 1, "0x627306090abaB3A6e1400e9345bC60c78a8BEf57");
    gen3s ++;
  }
  console.log("Cozy timed gen2s making gen3s");

  console.log("\n\n\n");
  console.log("Gen1s: " + gen1s);
  console.log("Gen2s: " + gen2s);
  console.log("Gen3s: " + gen3s);

  callback(undefined);

}
