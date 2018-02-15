pragma solidity ^0.4.18;


import "../DirectToken.sol";


// mock class using DirectToken
contract DirectTokenMock is DirectToken {

  function DirectTokenMock(address initialAccount, uint256 initialBalance) public {
    balances[initialAccount] = initialBalance;
    totalSupply_ = initialBalance;
  }

  function currentTime() public view returns (uint256) {
    return now;
  }

}
