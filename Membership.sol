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
