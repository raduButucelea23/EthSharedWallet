//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";


contract SharedWallet is Ownable, AccessControl {
    using SafeMath for uint256;

    event BalanceReceived (address indexed _from, uint256 _amount);
    event AmountSpent (address indexed _by, address indexed _to, uint256 _amount);

    bytes32 public constant FAMILY_ROLE = keccak256("FAMILY");
    bytes32 public constant ApprovedSpender_ROLE = keccak256("ApprovedSpender");

    mapping(bytes32 => uint256) public allowance;
    mapping(address => uint256) public remainingBalance;

//initializes the contract with the root address as admin
    constructor (address root) public {
        _setupRole(DEFAULT_ADMIN_ROLE, root);
        allowance[FAMILY_ROLE] = 1 ether;
        allowance[ApprovedSpender_ROLE] = 2 ether;
    }

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
    function addFamilyMember(address _account)
        public virtual
        {
            require(!hasRole(FAMILY_ROLE, _account),"Already a family member!");
            grantRole(FAMILY_ROLE, _account);
            remainingBalance[_account] = allowance[FAMILY_ROLE];
        }

    function addApprovedSpender(address _account)
        public virtual
        {
            require(!hasRole(ApprovedSpender_ROLE, _account),"Already an approved spender!");
            grantRole(ApprovedSpender_ROLE, _account);
            remainingBalance[_account]=allowance[ApprovedSpender_ROLE];
        }
//set allowance family and approved spenders
//allowance to be added to the remaining balance 
    // function addFamilyWhitelist(address[] memory familyAccounts)
    //     internal onlyAdmin
    //     {
    //         for (uint256 account = 0; account < familyAccounts.length; account++) {
    //             addFamilyWhitelist(familyAccounts[account]);
    //         }
    //     }
    
    // function SetAllowanceFamily(uint256 _Amount)  


//Send value function with input and overflow control
    function SendValue(address payable _to, uint256 _value)
        public payable OnlyMembers
        {
            require(remainingBalance[msg.sender] > _value, "Not enough money!");
            assert(remainingBalance[msg.sender] - _value < remainingBalance[msg.sender] );

            remainingBalance[msg.sender] -= _value;
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
