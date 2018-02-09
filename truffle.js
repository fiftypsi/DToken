var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "found crime side kingdom drum miss pioneer involve senior tell narrow riot";
module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
        host: "127.0.0.1",
        port: 8545,
        network_id: "*" // Match any network id
      },
    ropsten: {
        provider: function() {
          return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/StQ1HQ8bJaNgzDlUfIjD")
        },
        network_id: 3,
        gas: 4600000,
        gasPrice: 65000000000, // 65 gwei
      }
  },
};
