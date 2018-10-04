var PepeBase = artifacts.require("PepeBase");
var PepeAuction = artifacts.require("PepeAuctionSale");
var CozyAuction = artifacts.require("CozyTimeAuction");
var RevenueSplit = artifacts.require("RevenueSplit");
var PepToken = artifacts.require("PepToken.sol");
var Affiliate = artifacts.require("Affiliate.sol");
var PepeGrinder = artifacts.require("PepeGrinder.sol");
var Mining = artifacts.require("Mining.sol");

var BigNumber = require("bignumber.js");

var affiliateInstance;
var pepeBaseInstance;
var pepTokenInstance;
var pepeGrinderInstance;

// 1 deploy PepToken
// 2 deploy PepeBase
// 3 deploy PepeGrinder
// 4 deploy mining

module.exports =  function(deployer, network, accounts) {
  return deployer.deploy(PepToken, {from: accounts[0]}).then(function(instance) { //deploy pepToken
    pepTokenInstance = instance;
    return deployer.deploy(PepeBase); //deploy pepeBase
  }).then(function(instance) {
    pepeBaseInstance = instance;
    return deployer.deploy(PepeGrinder, PepeBase.address); //deploy pepeGrinder
  }).then(function(instance) {
    pepeGrinderInstance = instance;
  }).then(function() {
    return deployer.deploy(Mining, PepeBase.address, PepToken.address, PepeGrinder.address, 0);//deploy Mining last param should be timestamp when mining starts
  }).then(function() {
    return pepTokenInstance.transfer(Mining.address, web3.toWei(42500000, "ether"));
  }).then(function() {
    return pepeBaseInstance.setMiner(Mining.address);
  }).then(function() {
    return pepeGrinderInstance.setMiner(Mining.address);
  }).then(function() {
    return deployer.deploy(Affiliate);
  }).then(function() {
    return Affiliate.deployed();
  }).then(function(instance){
    affiliateInstance = instance;
    return deployer.deploy(PepeAuction, PepeBase.address, Affiliate.address);
  }).then(function() {
    return deployer.deploy(CozyAuction, PepeBase.address, Affiliate.address);
  }).then(function() {
    return affiliateInstance.setAffiliateSetter(PepeAuction.address);
  }).then(function() {
    return affiliateInstance.setAffiliateSetter(CozyAuction.address);
  }).then(function() {
    return deployer.deploy(RevenueSplit);
  });
};
