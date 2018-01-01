var SimpleToken = artifacts.require('./SimpleToken');

contract("SimpleToken", accounts => {

  var john = accounts[0];
  var jane = accounts[1];

  it("should have 10000 tokens", async () => {
    simpleToken = await SimpleToken.deployed();
    let totalSupply = await simpleToken.totalSupply.call();
    assert.equal(totalSupply.valueOf(), 10000000000000000000000, "TotalSupply is not 10000");
  })

  it("Transfer correctly", async () => {
    simpleToken.transfer(jane, 100, {from: john});
    let jane_balance = await simpleToken.balanceOf.call(jane);
    let john_balance = await simpleToken.balanceOf.call(john);
    assert.equal(jane_balance.valueOf(), 100, "Jane bal not 100");
    assert.equal(john_balance.valueOf(), 900, "John bal not 900");
  })

})
