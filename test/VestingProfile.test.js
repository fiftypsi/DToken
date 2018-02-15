import assertRevert from './helpers/assertRevert';
import latestTime from './helpers/latestTime';
import { increaseTimeTo, duration } from './helpers/increaseTime';

const debug = false;

var VestingProfile = artifacts.require("VestingProfile.sol");
var vestingProfile;

contract('VestingProfile', function([owner, beneficiary1, beneficiary2]) {


  beforeEach(async function () {
    this.vestingProfile = await VestingProfile.new();
    if (debug) { console.log('is deployed at ', this.vestingProfile.address); }
    this.start = latestTime() + duration.days(30 * 5);
    this.cliff = latestTime() + duration.days(30 * 6);
    this.vesting = latestTime() + duration.days(30 * 15);

    if (debug) { console.log('Vesting params: ', this.value, this.start, this.cliff, this.vesting); }
  });

  it("should have initial vesting grants storage empty", async function() {
    assert.equal(await this.vestingProfile.getVestingGrantValue(owner), 0, "grant value for owner is not 0");
    assert.equal(await this.vestingProfile.getVestingGrantValue(beneficiary1), 0, "grant value for beneficiary1 is not 0");
    assert.equal(await this.vestingProfile.getVestingGrantValue(beneficiary2), 0, "grant value for beneficiary2 is not 0");

  });

  it("should be able to set Token Grant", async function() {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    await this.vestingProfile.setVestingGrant( beneficiary2, 200, this.start, this.cliff, this.vesting, false );
    assert.equal(await this.vestingProfile.getVestingGrantValue(owner), 0, "grant value for owner should be 0");
    assert.equal(await this.vestingProfile.getVestingGrantValue(beneficiary1), 100, "grant for the beneficiary1 should be set to 100");
    assert.equal(await this.vestingProfile.getVestingGrantValue(beneficiary2), 200, "grant for the beneficiary2 should be set to 200");
  });

  it("should allow re-setting Token Grant to same beneficiary only when calling with override = true", async function() {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    assert.equal(await this.vestingProfile.getVestingGrantValue(beneficiary1), 100, "grant for the beneficiary1 should be set to 100");
    await this.vestingProfile.setVestingGrant( beneficiary1, 200, this.start, this.cliff, this.vesting, true );
    assert.equal(await this.vestingProfile.getVestingGrantValue(beneficiary1), 200, "grant for the beneficiary2 should be 200 after resetting");
  });

  it("should throw when re-setting Token Grant without calling with override = true", async function() {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    await assertRevert(this.vestingProfile.setVestingGrant( beneficiary1, 200, this.start, this.cliff, this.vesting, false ));
    assert.equal(await this.vestingProfile.getVestingGrantValue(beneficiary1), 100, "grant for the beneficiary1 should be still at 100 as previous call reverted");
  });

  it('locked amount is 100% before start', async function () {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    assert.equal(await this.vestingProfile.getLockedAmountOf( beneficiary1, this.start - duration.days(1)), 100, "Locked amount before start should be 100%");
  });

  it('locked amount is 100% before cliff', async function () {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    assert.equal(await this.vestingProfile.getLockedAmountOf( beneficiary1, this.cliff - duration.days(1)), 100, "Locked amount before cliff should be 100%");
  });

  it('locked at cliff is 90%', async function () {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    assert.equal(await this.vestingProfile.getLockedAmountOf( beneficiary1, this.cliff), 90, "Locked amount mismatch");
  });

  it('locked at 59 days is still 90% per monthly graded', async function () {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    assert.equal(await this.vestingProfile.getLockedAmountOf( beneficiary1, this.start + duration.days(59)), 90, "Locked amount mismatch");
  });

  it('locked at 60 days is 80%', async function () {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    assert.equal(await this.vestingProfile.getLockedAmountOf( beneficiary1, this.start + duration.days(60)), 80, "Locked amount mismatch");
  });

  it('locked at 10 months 0%', async function () {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    assert.equal(await this.vestingProfile.getLockedAmountOf( beneficiary1, this.start + duration.days(300)), 0, "Locked amount mismatch");
  });

  it('locked amount after vesting period 0%', async function () {
    await this.vestingProfile.setVestingGrant( beneficiary1, 100, this.start, this.cliff, this.vesting, false );
    assert.equal(await this.vestingProfile.getLockedAmountOf( beneficiary1, this.vesting), 0, "Locked amount mismatch");
  });

});
