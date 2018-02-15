pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Token Sale Configuration
// ----------------------------------------------------------------------------


contract DirectHomeVestingConfig  {

    uint256 public constant PRIVATESALE1_VESTING_START = 1517443200; // 2018-02-01 00:00:00 UTC
    uint256 public constant PRIVATESALE1_VESTING_CLIFF = PRIVATESALE1_VESTING_START + 86400 * 5;
    uint256 public constant PRIVATESALE1_VESTING_DURATION = PRIVATESALE1_VESTING_START + 86400 * 30 * 6;

    uint256 public constant PRIVATESALE2_VESTING_START = 1517443200; // 2018-02-01 00:00:00 UTC
    uint256 public constant PRIVATESALE2_VESTING_CLIFF = PRIVATESALE2_VESTING_START + 86400 * 5;
    uint256 public constant PRIVATESALE2_VESTING_DURATION = PRIVATESALE2_VESTING_START + 86400 * 30 * 6;

    uint256 public constant FOUNDER_VESTING_START = 1517443200; // 2018-02-01 00:00:00 UTC
    uint256 public constant FOUNDER_VESTING_CLIFF = FOUNDER_VESTING_START + 86400 * 10;
    uint256 public constant FOUNDER_VESTING_DURATION = FOUNDER_VESTING_START + 86400 * 30 * 24;

    
}
