pragma solidity ^0.4.18;

// combined Finalizable, Capped, Refundable Crowdsale
// renamed some variables for clarity of meaning
// added weiRaisedFromOthers, modified Capped definition to take into consideration of that
// sale constructor takes no parameters, but with defaults configured in config file
//   and added setters method for owner to change
// spelt out validPurchase requirement in buyTokens function directly
// made the sale contract pausable

import './SafeMath.sol';
import './Ownable.sol';
import './Pausable.sol';
import './SafeERC20.sol';
import './DirectToken.sol';
import './HasNoTokens.sol';
import './RefundVault.sol';
import "./DirectHomeCrowdsaleConfig.sol";
//import "./DirectHomeVestingHelper.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive. The contract requires a MintableToken that will be
 * minted as contributions arrive, note that the crowdsale contract
 * must be owner of the token in order to be able to mint it.
 */
contract DirectHomeCrowdsale is DirectHomeCrowdsaleConfig, Ownable, Pausable, HasNoTokens {
  using SafeMath for uint256;

  // The token being sold
  DirectToken public token; // = new DirectToken();

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime = CROWDSALE_START_TIME;
  uint256 public endTime = CROWDSALE_END_TIME;
  uint256 public pausedTime;

  // address where funds are collected
  address public multisigVault;
  RefundVault public refundVault = new RefundVault();

  // how many token units a buyer gets per wei
  uint256 public tokensPerEther = TOKENS_PER_ETHER;  // renamed from rate for the clarity

  // amount of raised money in wei from direct crowdsale purchase
  uint256 public weiRaised;
  // amount of raised money in wei for purchase in FIAT or altcoins
  uint256 public weiRaisedFromOthers;

  bool public isFinalized = false;
  uint256 public hardcap = HARDCAP;
  uint256 public softcap = SOFTCAP;

  // Map of addresses that have been whitelisted in advance (and passed KYC).
  mapping(address => uint8) public whitelist;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param weiAmount weis paid for purchase
   * @param tokens amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 weiAmount, uint256 tokens);

  event AuthorizedCreate(address beneficiary, uint256 tokens);
  event AuthorizedCreateWithVesting(address beneficiary, uint256 tokens, address vesting);
  event WhitelistUpdated(address indexed beneficiary);
  event Finalized();

  function DirectHomeCrowdsale(DirectToken _token) public {
    token = _token;
  }

  //function DirectHomeCrowdsale() public {  }

  // fallback function can be used to buy tokens
  function () external whenNotPaused payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(multisigVault != address(0));
    require(beneficiary != address(0));
    require(now >= startTime && now <= endTime);

    uint256 weiAmount = msg.value;
    require(weiAmount >= CONTRIBUTION_MIN);
    require(weiAmount <= CONTRIBUTION_MAX_NO_WHITELIST || whitelist[beneficiary] > 0);
    require(weiAmount.add(weiRaised).add(weiRaisedFromOthers) <= hardcap);

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  /**
   * @dev Allows authorized acces to create tokens. This is used for Bitcoin and ERC20 deposits
   * @param recipient the recipient to receive tokens.
   * @param tokens number of tokens to be created.
   */
  function authorizedCreateTokens(address recipient, uint256 tokens) public onlyOwner {
    token.mint(recipient, tokens);
    AuthorizedCreate(recipient, tokens);
  }

  /**
   * @dev Allows authorized acces to create tokens. This is used for Bitcoin and ERC20 deposits
   * @param recipient the recipient to receive tokens.
   * @param tokens number of tokens to be created.
   */
  function authorizedCreateTokensVesting(address vesting, address recipient, uint256 tokens) public onlyOwner returns(address) {
    //address vesting = new PrivateSaleVesting(recipient);
    token.mint(vesting, tokens);
    AuthorizedCreateWithVesting(recipient, tokens, vesting);
    return vesting;
  }

  // sets wei amount raised from others (Fiat and alt coins)
  function setWeiRaisedFromOthers(uint256 _weiRaisedFromOthers) public onlyOwner {
    weiRaisedFromOthers = _weiRaisedFromOthers;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended either due to time or hardcap
  function hasSaleEnded() public view returns (bool) {
    bool capReached = weiRaised.add(weiRaisedFromOthers) >= hardcap;
    return capReached || now > endTime;
  }


  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(tokensPerEther);   // note: both eth and DirectToken has 18 DECIMALS, hence omitting .div(10**(uint256(18) - TOKEN_DECIMALS))
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    //multisigVault.transfer(msg.value);
    refundVault.deposit.value(msg.value)(msg.sender);
  }


  /**
   * @dev Allows the owner to set the hardcap.
   * @param _hardcap the new hardcap
   */
  function setHardCap(uint _hardcap) public onlyOwner {
    hardcap = _hardcap;
  }

  /**
   * @dev Allows the owner to set the starting time.
   * @param _startTime the new startTime
   */
  function setStartTime(uint256 _startTime) public onlyOwner {
    startTime = _startTime;
  }

  /**
   * @dev Allows the owner to set the multisig contract.
   * @param _multisigVault the multisig contract address
   */
  function setMultisigVault(address _multisigVault) public onlyOwner {
    if (_multisigVault != address(0)) {
      multisigVault = _multisigVault;
      refundVault.setMultisigVault(_multisigVault);
    }
  }

  /**
   * @dev Allows the owner to set the exchangerate contract.
   * @param _tokensPerEther the exchangerate address
   */
  function setTokensPerEther(uint256 _tokensPerEther) public onlyOwner {
    tokensPerEther = _tokensPerEther;
  }

  //
  // WHITELIST
  //

  // Allows ops to add accounts to the whitelist.
  // Only those accounts will be allowed to contribute during the sale.
  // _phase = 1: Can contribute during phases 1 and 2 of the sale.
  // _phase = 2: Can contribute during phase 2 of the sale only.
  // _phase = 0: Cannot contribute at all (not whitelisted).
  function updateWhitelist(address _account) external onlyOwner returns (bool) {
      require(_account != address(0));
      whitelist[_account] = 1;
      WhitelistUpdated(_account);
      return true;
  }

  // if crowdsale is unsuccessful ie not hitting softcap, investors can claim refunds here
  function claimRefund() public {
    require(isFinalized);
    require(!softcapReached());

    refundVault.refund(msg.sender);
  }

  function softcapReached() public view returns (bool) {
    return weiRaised.add(weiRaisedFromOthers) >= softcap;
  }


  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasSaleEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  // vault finalization task, called when owner calls finalize()
  function finalization() internal {
    if (softcapReached()) {
      refundVault.close();
      uint issuedTokenSupply = token.totalSupply();
      uint restrictedTokens = issuedTokenSupply;
      token.mint(multisigVault, restrictedTokens);
      token.finishMinting();
      token.transferOwnership(owner);
    } else {
      refundVault.enableRefunds();
    }
  }


}
