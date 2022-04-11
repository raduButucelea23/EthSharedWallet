//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";

contract Membership is Ownable, AccessControl {
    
    bytes32 public constant FAMILY_ROLE = keccak256("FAMILY");
    bytes32 public constant ApprovedSpender_ROLE = keccak256("ApprovedSpender");
    
    mapping(bytes32 => uint256) public allowance;
    mapping(address => uint256) public remainingBalance;

    address payable[] internal AllFamilyAcc;
    address payable[] internal AllAppSpendersAcc;

    //define modifiers for permission control
    modifier onlyFamily() {
        require(isFamily(msg.sender), "Restricted to family members!");
        _;
        }

    modifier onlyApprovedSpender() {
        require(isApprovedSpender(msg.sender), "Restricted to approved spenders!");
        _;
        }
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _;
    }
    modifier OnlyMembers() {
        require(hasRole(ApprovedSpender_ROLE, msg.sender) || hasRole(FAMILY_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _;
    }

    //initializes the contract with the root address as admin
    constructor () public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        allowance[FAMILY_ROLE] = 1 ether;
        allowance[ApprovedSpender_ROLE] = 2 ether;
    }

    //function that validates role membership
    function isFamily(address _account)
        public virtual view returns(bool) 
        {
            return hasRole(FAMILY_ROLE, _account);
        }   

    function isApprovedSpender(address _account)
        public virtual view returns(bool)
        {
            return hasRole(ApprovedSpender_ROLE, _account);
        }

    //function that easily adds members to the different groups and initializes their balance
    //adds input checking to avoid balance re-initialization with every "add" function call
    function addFamilyMember(address payable _account)
        public virtual
        {
            require(!hasRole(FAMILY_ROLE, _account),"Already a family member!");
            grantRole(FAMILY_ROLE, _account);
            remainingBalance[_account] = allowance[FAMILY_ROLE];
            AllFamilyAcc.push(payable(_account));
        }
    function addApprovedSpender(address payable _account)
        public virtual
        {
            require(!hasRole(ApprovedSpender_ROLE, _account),"Already an approved spender!");
            grantRole(ApprovedSpender_ROLE, _account);
            remainingBalance[_account] = allowance[ApprovedSpender_ROLE];
            AllAppSpendersAcc.push(payable(_account));
        }
    
    //removing support for the "renounceOwnership" function
    function renounceOwnership() public override {
        revert("Function not supported!");
    }
    
}

contract Allowance is Membership {

    using SafeMath for uint;
    event allowanceUpdate (bytes32 indexed _FamilyRole, bytes32 indexed _AppSpenderRole, uint256 _FamAllowance, uint256 _AppSpeAllow);

    //set allowance family and approved spenders
    //allowance to be added to the remaining balance 
    function SetAllowance(uint256 _FamilyAmount, uint256 _AppSpenderAmount)
        public payable
        {
        
        emit allowanceUpdate (FAMILY_ROLE, ApprovedSpender_ROLE, _FamilyAmount, _AppSpenderAmount);

        //family update loop
        for (uint i=0; i<=AllFamilyAcc.length; i++) {
              
              //AllFamilyAcc[i].transfer(_FamilyAmount);
              remainingBalance[AllFamilyAcc[i]] = remainingBalance[AllFamilyAcc[i]].add(_FamilyAmount);
          }

        //approved spender array
        for (uint i=0; i<=AllAppSpendersAcc.length; i++) {
            //   AllAppSpendersAcc[i].transfer(_AppSpenderAmount);
              remainingBalance[AllAppSpendersAcc[i]] = remainingBalance[AllAppSpendersAcc[i]].add(_AppSpenderAmount);
          }
        }

}

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
