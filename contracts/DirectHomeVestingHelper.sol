pragma solidity ^0.4.18;

import "./TokenVesting.sol";
import "./DirectHomeVestingConfig.sol";

contract PrivateSaleVesting is TokenVesting, DirectHomeVestingConfig {
  function PrivateSaleVesting(address _beneficiary)
    TokenVesting(_beneficiary, PRIVATESALE_VESTING_START, PRIVATESALE_VESTING_CLIFF,
      PRIVATESALE_VESTING_DURATION, true) public {
      }
}

contract FounderVesting is TokenVesting, DirectHomeVestingConfig {
  function FounderVesting(address _beneficiary)
    TokenVesting(_beneficiary, FOUNDER_VESTING_START, FOUNDER_VESTING_CLIFF,
      FOUNDER_VESTING_DURATION, true) public {
      }
}
