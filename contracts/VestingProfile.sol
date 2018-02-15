pragma solidity ^0.4.18;

import "./SafeMath.sol";

/**
 * @title Standalone Vesting Profile logic to be added in token
 * @dev Beneficiary can have at most one VestingGrant only, we do not support adding two vesting grants of vesting grant to same address.
 *      Token transfer related logic is not handled in this class for simplicity and modularity purpose
 */
contract VestingProfile {
  using SafeMath for uint256;

  struct VestingGrant {
    uint256 value;       // 32 bytes
    uint64 cliff;
    uint64 vesting;
    uint64 start;        // 3 * 8 = 24 bytes
  } // total 56 bytes = 2 sstore per operation (32 per sstore)

  mapping (address => VestingGrant) public grants;

  event VestingGrantSet(address indexed to, uint256 value, uint64 vesting);

  function getVestingGrantValue(address _to) public view returns (uint256) {
    return grants[_to].value;
  }

  /**
   * @dev Set vesting grant to a specified address
   * @param _to address The address which the vesting amount will be granted to.
   * @param _value uint256 The amount to be granted.
   * @param _start uint64 Time of the beginning of the grant.
   * @param _cliff uint64 Time of the cliff period.
   * @param _vesting uint64 The vesting period.
   * @param _override bool Must be true if you are overriding vesting grant that has been set before
   *          this is to prevent accidental overwriting vesting grant
   */
  function setVestingGrant(address _to, uint256 _value, uint64 _start, uint64 _cliff, uint64 _vesting, bool _override) public {

    // Check for date inconsistencies that may cause unexpected behavior
    require(_cliff >= _start && _vesting >= _cliff);
    require(grants[_to].value == 0 || _override);
    grants[_to] = VestingGrant(_value, _cliff, _vesting, _start);

    VestingGrantSet(_to, _value, _vesting);
  }

  /**
   * @dev Calculate amount of vested amounts at a specific time (monthly graded)
   * @param amounts uint256 The amount of amounts granted
   * @param time uint64 The time to be checked
   * @param start uint64 The time representing the beginning of the grant
   * @param cliff uint64  The cliff period, the period before nothing can be paid out
   * @param vesting uint64 The vesting period
   * @return An uint256 representing the vested amounts
   *   |                         _/--------   vestedTokens rect
   *   |                       _/
   *   |                     _/
   *   |                   _/
   *   |                 _/
   *   |                /
   *   |              .|
   *   |            .  |
   *   |          .    |
   *   |        .      |
   *   |      .        |
   *   |    .          |
   *   +===+===========+---------+----------> time
   *      Start       Cliff    Vesting
   */
  function calculateVested (
    uint256 amounts,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) internal pure returns (uint256)
    {
      // Shortcuts for before cliff and after vesting cases.
      if (time < cliff) return 0;
      if (time >= vesting) return amounts;

      // Interpolate all vested amounts.
      // As before cliff the shortcut returns 0, we can use just calculate a value
      // in the vesting rect (as shown in above's figure)

      // vestedAmounts = (amounts * (time - start)) / (vesting - start)
      // vestedAmounts = (amounts * ( (time - start) / (30 days) ) / ( (vesting - start) / (30 days) )
      /*
      uint256 vestedAmounts = SafeMath.div(
                                    SafeMath.mul(
                                      amounts,
                                      SafeMath.div(SafeMath.sub(time, start), 30 days)
                                      ),
                                    SafeMath.div(SafeMath.sub(vesting, start), 30 days)
                                    ); */
      uint256 vestedAmounts = amounts.mul(time.sub(start).div(30 days)).div(vesting.sub(start).div(30 days));

      // if (vestedAmounts > amounts) return amounts; // there is possible case where this is true

      return vestedAmounts;
  }

  function calculateLocked (
    uint256 amounts,
    uint256 time,
    uint256 start,
    uint256 cliff,
    uint256 vesting) internal pure returns (uint256)
    {
      return amounts.sub(calculateVested(amounts, time, start, cliff, vesting));
    }

  /**
   * @dev Gets the locked amount of a given beneficiary, ie. non vested amount, at a specific time.
   * @param _to The beneficiary to be checked.
   * @param _time uint64 The time to be checked
   * @return An uint256 representing the non vested amounts of a specific grant on the
   * passed time frame.
   */
  function getLockedAmountOf(address _to, uint256 _time) public view returns (uint256) {
    VestingGrant storage grant = grants[_to];
    if (grant.value == 0) return 0;
    return calculateLocked(grant.value, uint256(_time), uint256(grant.start),
      uint256(grant.cliff), uint256(grant.vesting));
  }


}
