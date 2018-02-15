pragma solidity ^0.4.18;

import "./MintableToken.sol";
import "./HasNoTokens.sol";
import "./VestingProfile.sol";

contract DirectToken is MintableToken, HasNoTokens, VestingProfile {

  string public constant name = "Kiegan Token 2";
  string public constant symbol = "KG2";
  uint8 public constant decimals = 18;

  bool public tradingStarted = false;

  /**
   * @dev Allows the owner to enable the trading.
   */
  function setTradingStarted(bool _tradingStarted) public onlyOwner {
    tradingStarted = _tradingStarted;
  }

  /**
   * @dev Allows anyone to transfer the PAY tokens once trading has started
   * @param _to the recipient address of the tokens.
   * @param _value number of tokens to be transfered.
   */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    checkTransferAllowed(msg.sender, _to, _value);
    return super.transfer(_to, _value);
  }

   /**
   * @dev Allows anyone to transfer the PAY tokens once trading has started
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    checkTransferAllowed(msg.sender, _to, _value);
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * Throws if the transfer not allowed due to minting not finished, trading not started, or vesting
   *   this should be called at the top of transfer functions and so as to refund unused gas
   */
  function checkTransferAllowed(address _sender, address _to, uint256 _value) private view {
      if (mintingFinished && tradingStarted && isAllowableTransferAmount(_sender, _value)) {
          // Everybody can transfer once the token is finalized and trading has started and is within allowable vested amount if applicable
          return;
      }

      // Owner is allowed to transfer tokens before the sale is finalized.
      // This allows the tokens to move from the TokenSale contract to a beneficiary.
      // We also allow someone to send tokens back to the owner. This is useful among other
      // cases, reclaimTokens etc.
      require(_sender == owner || _to == owner);
  }

  function setVestingGrant(address _to, uint256 _value, uint64 _start, uint64 _cliff, uint64 _vesting, bool _override) public onlyOwner {
    return super.setVestingGrant(_to, _value, _start, _cliff, _vesting, _override);
  }

  function isAllowableTransferAmount(address _sender, uint256 _value) private view returns (bool allowed) {
     if (getVestingGrantValue(_sender) == 0) {
        return true;
     }
     uint256 transferableAmount = balanceOf(_sender).sub(getLockedAmountOf(_sender, now));
     return (_value <= transferableAmount);
  }

}
