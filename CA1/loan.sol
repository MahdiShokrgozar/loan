// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Loan{
    struct LoanRequest{
        address payable brrower;
        address payable guarantor;
        address payable lender;
        uint256 original_amount;
        uint256 interest;
        uint256 payback_period;
        uint256 guarantor_interest;
        uint256 lender_interest;
        uint256 status;
    }
    struct ShowLoan{
        uint256 id;
        uint256 original_amount;
        uint256 interest;
        uint256 payback_period;
        uint256 lender_interest;
    }

    uint256 _totlaRequests;
    mapping (uint256=>LoanRequest) public loanRequests;
    // address payable brrower;

    event showLoanRequests(address thisbrrower,LoanRequest loanRequests);
    event showLoan(uint256 id,uint256 original_amount, uint256 interest,
                uint256 payback_period,uint256 lender_interest);


    constructor() public {
        _totlaRequests=0;
    }

    // modifier notCreated(address payable brrower){
    //     require(loanRequests[brrower].brrower!=brrower,"Loan has already created");
    //     _;
    // }
    // modifier isLender{
    //     require(msg.sender==myLoan.lender);
    //     _;
    // }

    function loanRequest(uint256 original_amount,uint256 interest, uint256 payback_period)
             public {
                 address payable brrower=payable(msg.sender);
               
                createLoan(original_amount,interest,payback_period,brrower);
                //  emit showLoanRequests(msg.sender,loanRequests[brrower]);
                
    }
    function createLoan(uint256 original_amount,uint256 interest, uint256 payback_period,address payable brrower) 
            public  returns(bool){
                LoanRequest storage myLoan=loanRequests[_totlaRequests];
                myLoan.brrower=brrower;
                myLoan.original_amount=original_amount;
                myLoan.interest=interest;
                myLoan.payback_period=payback_period;
                _totlaRequests++;
                return true;
    }

    function getLoans(uint256 status) public returns(ShowLoan[] memory){
        ShowLoan[] memory requests=new ShowLoan[](_totlaRequests);
        
        for(uint256 i; i<_totlaRequests;i++){
            if (loanRequests[i].status==status){
                LoanRequest memory request=loanRequests[i];
                requests[i].id=i;
                requests[i].original_amount=request.original_amount;
                requests[i].interest=request.interest;
                requests[i].payback_period=request.payback_period;
                requests[i].lender_interest=request.lender_interest;
                emit showLoan(i,request.original_amount,request.interest,request.payback_period,
                            request.lender_interest);
            }
            
        }

        return requests;
    }
    function getInterest() public payable {

    }
}
