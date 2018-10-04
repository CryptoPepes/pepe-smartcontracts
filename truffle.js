var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "tongue kick couple practice clever bottom cool dial elder potato special rebel";

module.exports = {
  solc: {
    optimizer: {
      enabled: true,
      runs: 500
    }
  },
  networks: {
    development: {
      host: "localhost",
      port: 9545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/CwrqagDYoSGcu8DH1Oaq")
      },
      network_id: "*"
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/CwrqagDYoSGcu8DH1Oaq")
      },
      gas: 4500000,
      network_id: "*"
    }

  }
};
