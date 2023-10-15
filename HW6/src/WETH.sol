// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract WETH is IERC20 {

  error InvalidAccount();
  error InsufficientBalance();
  error InsufficientAllowance();
  error WithdrawFail();

  event Deposit(address indexed to, uint256 value);
  event Withdraw(address indexed from, uint256 value);

  // 1 ETH = 1WETH, 
  // so WETH total supply is accroding to the eth balance in this contract
  function totalSupply() external view returns (uint256) {
    return address(this).balance;
  }

  // record each user passbook
  mapping (address => uint256) private _passbook;

  // get specific user balance
  function balanceOf(address owner) external view returns (uint256) {
    return _passbook[owner];
  }

  // get sender own balance
  function myBalance() external view returns (uint256) {
    return _passbook[msg.sender];
  }

  // record total amount of authorized owner's coin to the spender
  // use a two layer mapping to record owner/spender/coin relationship
  mapping (address => mapping (address => uint256)) private _allowed;

  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowed[owner][spender];
  }

  // approve spender can spend specific amount of coin from transaction sender
  function approve(address spender, uint256 value) external returns (bool) {
    if(spender == address(0)) {
      revert InvalidAccount();
    }
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function _transfer(address from, address to, uint256 value) internal {
    if(to == address(0)) {
      revert InvalidAccount();
    }
    // check sender balance
    uint256 senderBalance = _passbook[from];
    if(senderBalance < value) {
      revert InsufficientBalance();
    }
    
    // decrease sender balance
    _passbook[from] = senderBalance - value;
    // increase receiver balance
    _passbook[to] = _passbook[to] + value;
  }

  function transfer(address to, uint256 value) external returns (bool) {
    _transfer(msg.sender, to, value);
    emit Transfer(msg.sender, to, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) external returns (bool) {
    // check spender allowed quato
    if(_allowed[from][msg.sender] < value) {
      revert InsufficientAllowance();
    }

    // decrease quato
    _allowed[from][msg.sender] = _allowed[from][msg.sender] - value;
    emit Transfer(from, to, value);
    return true;
  }

  function deposit() external payable returns(bool) {
    // add WETH balance for the amount of receiving ETH
    _passbook[msg.sender] = _passbook[msg.sender] + msg.value;
    // use address 0 as transfer sender for mint like a "coinbase transaction"
    // emit Transfer(address(0), msg.sender, msg.value);
    emit Deposit(msg.sender, msg.value);
    return true;
  }

  function withdraw(uint value) external returns(bool) {
    uint256 senderBalance = _passbook[msg.sender];
    if(senderBalance < value) {
      revert InsufficientBalance();
    }

    // decrease WETH for transaction sender balance 
    _passbook[msg.sender] = senderBalance - value;

    // send ETH back to transaction sender address
    bool sent = payable(msg.sender).send(value);
    if(!sent) {
      revert WithdrawFail();
    }
    // emit Transfer(msg.sender, address(0), value);
    emit Withdraw(msg.sender, value);

    return true;
  }
}