pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// Token Sale Configuration
// ----------------------------------------------------------------------------


contract DirectHomeCrowdsaleConfig  {

    uint256 public constant CROWDSALE_START_TIME      = 1517443200; // 2018-02-01 00:00:00 UTC
    uint256 public constant CROWDSALE_END_TIME        = 1530403199; // 2018-06-30 23:59:59 UTC
    uint256 public constant CONTRIBUTION_MIN          = 0.1 ether;
    uint256 public constant CONTRIBUTION_MAX_NO_WHITELIST  = 25 ether;    // maximum acceptable contribution without whitelisting
    uint256 public constant HARDCAP                   =  50000 ether;
    uint256 public constant SOFTCAP                   =  3750 ether;

    //uint256 public constant TARGET_ETH_SOFT_CAP       = 100000;


    // Default conversion rate when deployed, changable later by
    // calling the setTokensPerWei function on TokenSale contract

    // For illustration: tokens are priced at 1 USD/token.
    // So if we have 800 USD/ETH -> 800 USD/ETH / 0.8 USD/token = ~1000
    uint256 public constant TOKENS_PER_ETHER       = 1000; // 10**(uint256(18));  // eg

}
