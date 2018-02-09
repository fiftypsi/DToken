var dtoken = artifacts.require("DirectToken.sol");
var dhsale = artifacts.require("DirectHomeCrowdsale.sol");

//module.exports = function(deployer) {
//  deployer.deploy(dhsale);
//};

module.exports = function(deployer, network, accounts) {

  const ourSecureAddress = '0x6Ba2e5e54b2D891f2Af18b09EaC5627f0E3A2998'

  var token = null
  var sale = null

  console.log('Start deploying');
  return deployer.deploy(dtoken, { from: accounts[0], gas: 4700000 }).then(() => {

    return dtoken.deployed().then(instance => { token = instance })

  }).then(() => {

    console.log('DirectToken deployed at : ' + token.address);
    console.log('Going to deploy sale contract');


    return deployer.deploy(dhsale, token.address,{ from: accounts[0], gas: 4500000 })
  //return deployer.deploy(dhsale, { from: accounts[0], gas: 4500000 })

  }).then(() => {

    return dhsale.deployed().then(instance => { sale = instance })

  }).then(() => {
    console.log('Sale contract deployed at : ' + sale.address);


    console.log('Setting sale contract to be the owner of token contract');
    return token.transferOwnership(sale.address);

  }).then(() => {
    console.log('Setting ourSecureAddress to be the multisigVault of sale contract, ourSecureAddress=' + ourSecureAddress);
    return sale.setMultisigVault(ourSecureAddress);

  }).then(() => {
    console.log('Setting ourSecureAddress to be the owner of sale contract, ourSecureAddress=' + ourSecureAddress);
    return sale.transferOwnership(ourSecureAddress);

  }).then(() => {

    console.log('Deployment completed!');
    
  })

}
