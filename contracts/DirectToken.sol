pragma solidity ^0.4.18;

import "./MintableToken.sol";
import "./HasNoTokens.sol";

contract DirectToken is MintableToken, HasNoTokens {

  string public constant name = "Kiegan Token 1";
  string public constant symbol = "KG1";
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
  function transfer(address _to, uint _value) public returns (bool success) {
    checkTransferAllowed(msg.sender, _to);
    return super.transfer(_to, _value);
  }

   /**
   * @dev Allows anyone to transfer the PAY tokens once trading has started
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    checkTransferAllowed(msg.sender, _to);
    return super.transferFrom(_from, _to, _value);
  }

  function checkTransferAllowed(address _sender, address _to) private view {
      if (mintingFinished && tradingStarted) {
          // Everybody can transfer once the token is finalized and trading has started
          return;
      }

      // Owner is allowed to transfer tokens before the sale is finalized.
      // This allows the tokens to move from the TokenSale contract to a beneficiary.
      // We also allow someone to send tokens back to the owner. This is useful among other
      // cases, reclaimTokens etc.
      require(_sender == owner || _to == owner);
  }
}
