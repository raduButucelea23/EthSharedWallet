//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Membership.sol";

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

