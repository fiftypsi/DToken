pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Token Sale Configuration
// ----------------------------------------------------------------------------


contract DirectHomeVestingConfig  {

    uint256 public constant PRIVATESALE_VESTING_START = 1517443200; // 2018-02-01 00:00:00 UTC
    uint256 public constant PRIVATESALE_VESTING_CLIFF = 86400 * 5;
    uint256 public constant PRIVATESALE_VESTING_DURATION = 86400 * 30 * 6;

    uint256 public constant FOUNDER_VESTING_START = 1517443200; // 2018-02-01 00:00:00 UTC
    uint256 public constant FOUNDER_VESTING_CLIFF = 86400 * 10;
    uint256 public constant FOUNDER_VESTING_DURATION = 86400 * 30 * 24;

}
