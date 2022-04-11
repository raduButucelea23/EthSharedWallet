//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Membership.sol";
import "./Allowance.sol";

contract SharedWallet is Membership, Allowance {
    using SafeMath for uint;

    event BalanceReceived (address indexed _from, uint256 _amount);
    event AmountSpent (address indexed _by, address indexed _to, uint256 _amount);

    modifier TransferBalanceCheck(uint256 _value) {
        require(remainingBalance[msg.sender] > _value, "Not enough money!");
        require(_value<= address(this).balance, "The smart contract does not have enough funds!");
        _;
    }
    
    function reduceBalance(uint256 _value) internal {
        remainingBalance[msg.sender] = remainingBalance[msg.sender].sub(_value);
    }

    //Send value function with input and overflow control
    function SendValue(address payable _to, uint256 _value)
        public payable 
        OnlyMembers TransferBalanceCheck(_value)
        {
            reduceBalance(_value);            
            emit AmountSpent (msg.sender, _to, _value);
            _to.transfer(_value);
        }
    
    //"receive" fallback
    receive() external payable {
        emit BalanceReceived (msg.sender, msg.value);
    }
    //fallback function
    fallback() external payable {
        emit BalanceReceived (msg.sender, msg.value);
    }
        
    //Shows the contract's balance
    function ContractBalance() external view onlyOwner returns(uint256) {
        return address(this).balance;
    }

}