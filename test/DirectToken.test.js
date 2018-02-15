import assertRevert from './helpers/assertRevert';
import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const debug = true;

var DirectTokenMock = artifacts.require('mocks/DirectTokenMock.sol');

contract('DirectToken', function ([owner, beneficiary1, beneficiary2, beneficiary3]) {
  var start = latestTime() + duration.days(30 * 5);
  var cliff = latestTime() + duration.days(30 * 6);
  var vesting = latestTime() + duration.days(30 * 15);

  it('should return the correct totalSupply after construction', async function () {
    let token = await DirectTokenMock.new(owner, 100);
    let totalSupply = await token.totalSupply();

    assert.equal(totalSupply, 100);
  });

  it('should return correct balances after transfer', async function () {
    let token = await DirectTokenMock.new(owner, 100);
    await token.transfer(beneficiary1, 100);

    let firstAccountBalance = await token.balanceOf(owner);
    assert.equal(firstAccountBalance, 0);

    let secondAccountBalance = await token.balanceOf(beneficiary1);
    assert.equal(secondAccountBalance, 100);
  });

  it('should throw an error when trying to transfer more than balance', async function () {
    let token = await DirectTokenMock.new(owner, 100);
    await assertRevert(token.transfer(beneficiary1, 101));
  });

  it('should throw an error when trying to transfer to 0x0', async function () {
    let token = await DirectTokenMock.new(owner, 100);
    await assertRevert(token.transfer(0x0, 100));
  });

  it('should allow owner to set vesting grant', async function () {
    let token = await DirectTokenMock.new(owner, 1000);
    await token.setVestingGrant( beneficiary1, 100, start, cliff, vesting, false );
    assert.equal(await token.getVestingGrantValue(beneficiary1), 100, "grant for the beneficiary1 should be set to 100");
    await token.transfer(beneficiary1, 100);
  });

  it('should throw an error when someone other than owner trying to set vesting grant', async function () {
    let token = await DirectTokenMock.new(owner, 1000);
    await assertRevert(token.setVestingGrant( beneficiary1, 100, start, cliff, vesting, false, { from: beneficiary1 }));
    await assertRevert(token.setVestingGrant( beneficiary1, 100, start, cliff, vesting, false, { from: beneficiary2 }));
  });

  it('vesting grant beneficiary should not be allowed to transfer before start/cliff', async function () {
    let token = await DirectTokenMock.new(owner, 1000);
    await token.setVestingGrant( beneficiary1, 100, start, cliff, vesting, false );
    assert.equal(await token.getVestingGrantValue(beneficiary1), 100, "grant for the beneficiary1 should be set to 100");
    await token.transfer(beneficiary1, 100);
    assert.equal(await token.balanceOf(beneficiary1), 100);

    await assertRevert(token.transfer(beneficiary2, 10, { from: beneficiary1 }));

    // even after owner finishMinting and setTradingStarted
    await token.finishMinting();
    await token.setTradingStarted(true);
    await assertRevert(token.transfer(beneficiary2, 10, { from: beneficiary1 }));

    //even after we move the time to start - 5 minutes
    let t0 = await token.currentTime();
    if (debug) console.log('token now is ', t0);
    if (debug) console.log('Trying to set current time to before start = ', start);
    await increaseTimeTo(start - duration.minutes(2));
    let t1 = await token.currentTime();

    if (debug) console.log('token now is ', t1);
    await assertRevert(token.transfer(beneficiary2, 10, { from: beneficiary1 }));

  });

  it('show allow vesting grant beneficiary to transfer after start/cliff', async function () {
    let token = await DirectTokenMock.new(owner, 1000);
    await token.setVestingGrant( beneficiary1, 100, start, cliff, vesting, false );
    assert.equal(await token.getVestingGrantValue(beneficiary1), 100, "grant for the beneficiary1 should be set to 100");
    await token.transfer(beneficiary1, 100);
    assert.equal(await token.balanceOf(beneficiary1), 100);

    await token.finishMinting();
    await token.setTradingStarted(true);

    let t0 = await token.currentTime();

    if (debug) console.log(beneficiary1, t0, await token.getLockedAmountOf(beneficiary1, t0));

    if (debug) console.log('token now is ', t0);
    if (debug) console.log('Trying to set current time to cliff = ', cliff);
    await increaseTimeTo(cliff);
    let t1 = await token.currentTime();

    if (debug) console.log('token now is ', t1);
    if (debug) console.log('latestTime() is ', latestTime());
    if (debug) console.log(beneficiary1, t1, await token.getLockedAmountOf(beneficiary1, t1));

    await token.transfer(beneficiary2, 10, { from: beneficiary1 });
    assert.equal(await token.balanceOf(beneficiary1), 90);
    assert.equal(await token.balanceOf(beneficiary2), 10);

    // and further no more vesting on the recipient or thereafter
    await token.transfer(beneficiary3, 10, { from: beneficiary2 });
    assert.equal(await token.balanceOf(beneficiary2), 0);
    assert.equal(await token.balanceOf(beneficiary3), 10);

    // and further no more vesting on the recipient or thereafter
    await token.transfer(beneficiary2, 2, { from: beneficiary3 });
    assert.equal(await token.balanceOf(beneficiary2), 2);
    assert.equal(await token.balanceOf(beneficiary3), 8);

  });

  it('should monthly-graded release tokens during vesting period', async function () {

    let token = await DirectTokenMock.new(owner, 1000);
    await token.setVestingGrant( beneficiary1, 100, start, cliff, vesting, false );
    await token.transfer(beneficiary1, 100);
    let amount = await token.getVestingGrantValue(beneficiary1);

    await token.finishMinting();
    await token.setTradingStarted(true);

    const vestingPeriod = vesting - cliff;
    const checkpoints = 4;

    console.log('Start='+ new Date(start * 1000), 'Cliff='+ new Date(cliff * 1000), 'Vesting='+ new Date(vesting * 1000));
    for (let i = 1; i <= checkpoints; i++) {
      const t = cliff + i * (vestingPeriod / checkpoints);
      await increaseTimeTo(t);

      let nonVestedAmount = await token.getLockedAmountOf(beneficiary1, t);
      const expectedVested = amount.mul( Math.floor((t - start) / duration.days(30) ) ).div( Math.floor((vesting - start)/duration.days(30)) ).floor();
      console.log('At time ' + i, new Date(t * 1000), 'Locked amount = ' + nonVestedAmount, ', vestedAmount = ' + expectedVested);
      assert.equal(nonVestedAmount, 100 - expectedVested, 'vested amount does not match expected');

      let currentBalance = await token.balanceOf(beneficiary1);

      //make sure we can really transfer that amount
      await token.transfer(beneficiary2, currentBalance - nonVestedAmount, { from: beneficiary1 });

      //can't event transfer 1 more
      await assertRevert(token.transfer(beneficiary2, 1, { from: beneficiary1 }));
    }

  });

});
