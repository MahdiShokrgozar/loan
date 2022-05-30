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
        uint256 guarantor_interest;
        uint256 lender_interest;
    }

    // fallback pay() external payable {};
    uint256 _totlaRequests;
    mapping (uint256=>LoanRequest) private loan_requests;
    // mapping (uint256=>GuaranteeOffer) private guarantee_offers;

    // address payable brrower;

    // event showLoanRequests(address thisbrrower,LoanRequest loan_requests);
    event showLoans(uint256 id,uint256 original_amount, uint256 interest,
                uint256 payback_period,uint guarantor_interest,uint256 lender_interest);
    event balance(uint256 balance);

    constructor() public {
        _totlaRequests=0;
    }

    // modifier notCreated(address payable brrower){
    //     require(loan_requests[brrower].brrower!=brrower,"Loan has already created");
    //     _;
    // }
    // modifier isLender{
    //     require(msg.sender==myLoan.lender);
    //     _;
    // }

    function loanRequest(uint256 original_amount,uint256 interest, uint256 payback_period)
             external {
                 address payable brrower=payable(msg.sender);
               
                createLoan(original_amount,interest,payback_period,brrower);
                //  emit showLoanRequests(msg.sender,loan_requests[brrower]);
                
    }
    function createLoan(uint256 original_amount,uint256 interest, uint256 payback_period,address payable brrower) 
            private  returns(bool){
                LoanRequest storage myLoan=loan_requests[_totlaRequests];
                myLoan.brrower=brrower;
                myLoan.original_amount=original_amount;
                myLoan.interest=interest;
                myLoan.payback_period=payback_period;
                _totlaRequests++;
                return true;
    }

    function showLoanRequests(uint256 status) public returns(ShowLoan[] memory){
        ShowLoan[] memory requests=new ShowLoan[](_totlaRequests);
        
        for(uint256 i; i<_totlaRequests;i++){
            if (loan_requests[i].status==status){
                LoanRequest memory request=loan_requests[i];
                requests[i].id=i;
                requests[i].original_amount=request.original_amount;
                requests[i].interest=request.interest;
                requests[i].payback_period=request.payback_period;
                requests[i].guarantor_interest=request.guarantor_interest;
                requests[i].lender_interest=request.lender_interest;
                emit showLoans(i,request.original_amount,request.interest,request.payback_period,
                            request.guarantor_interest,request.lender_interest);
            }
            
        }

        return requests;
    }
    function showMyRequest() public {
        
        for(uint256 i; i<_totlaRequests;i++){
            if (loan_requests[i].brrower==payable(msg.sender)){
                LoanRequest memory request=loan_requests[i];
                emit showLoans(i,request.original_amount,request.interest,request.payback_period,
                            request.guarantor_interest,request.lender_interest);    
        
            }
        }
    }

    function setGuarantor(uint256 _id,uint256 _g, address payable _guarantor) private {
        loan_requests[_id].guarantor_interest=_g;
        loan_requests[_id].guarantor=_guarantor;
    }
    function removeGuarantor(uint256 _id) private {
        loan_requests[_id].guarantor_interest=0;
        loan_requests[_id].guarantor=payable(0x00);
    }
    
    function guarateeOffer(uint256 id,uint256 g) public payable {
        require(msg.value==loan_requests[id].original_amount,"you should pay original amount of loanRequest");
        require(loan_requests[id].guarantor_interest==0,"another guarator requested");
        setGuarantor(id,g,payable(msg.sender));
        emit balance(address(this).balance);
           
    }
    

    function setGuaranteeOffers(uint256 id,bool accept) public{
        require(loan_requests[id].brrower==msg.sender,"you cant accept or reject the guarantee offer");
        require(loan_requests[id].status==0,"you can't change status");
        require(loan_requests[id].guarantor!=payable(0x00),"another guarator requested");
        if(accept){
            loan_requests[id].status=1;
        }else{
            removeGuarantor(id);
            loan_requests[id].guarantor.transfer(loan_requests[id].original_amount);
        }
    }
    function getInterest() public payable {

    }
}

