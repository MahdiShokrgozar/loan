// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Loan {
    struct LoanRequest {
        address payable brrower;
        address payable guarantor;
        address payable lender;
        uint256 original_amount;
        uint256 interest;
        uint256 payback_period;
        uint256 guarantor_interest;
        uint256 lender_interest;
        uint256 time_started;
        uint256 status;
    }
    struct ShowLoan {
        uint256 id;
        uint256 original_amount;
        uint256 interest;
        uint256 payback_period;
        uint256 guarantor_interest;
        uint256 lender_interest;
    }

    enum actions {
        guarantee,
        acceptguarantee,
        lend,
        paybackloan,
        requestlend
    }
    uint256 _totlaRequests;
    mapping(uint256 => LoanRequest) private loan_requests;

    event showLoans(
        uint256 id,
        uint256 original_amount,
        uint256 interest,
        uint256 payback_period,
        uint256 guarantor_interest,
        uint256 lender_interest,
        uint256 time_started,
        uint256 status
    );
    event balance(uint256 balance);

    constructor() public {
        _totlaRequests = 0;
    }

    // ++++++++++++++++++++++++++++++++++  MODIFIERS +++++++++++++++++++++++++++++++++++++++++
    modifier notBrrower(uint256 id) {
        require(
            msg.sender != loan_requests[id].brrower,
            "you can't guarantee or lend on your loan request"
        );
        _;
    }

    // ================================== private functions ==================================

    // ---------------------------------- Create Loan -----------------------------------------
    function createLoan(
        uint256 original_amount,
        uint256 interest,
        uint256 payback_period,
        address payable brrower
    ) private returns (bool) {
        LoanRequest storage myLoan = loan_requests[_totlaRequests];
        myLoan.brrower = brrower;
        myLoan.original_amount = original_amount;
        myLoan.interest = interest;
        myLoan.payback_period = payback_period;
        _totlaRequests++;
        return true;
    }

    function removeGuarantor(uint256 _id) private {
        loan_requests[_id].guarantor_interest = 0;
        loan_requests[_id].guarantor = payable(0x00);
    }

    function setGuarantor(
        uint256 _id,
        uint256 _g,
        address payable _guarantor
    ) private {
        loan_requests[_id].guarantor_interest = _g;
        loan_requests[_id].guarantor = _guarantor;
    }

    // --------------------------------- Set Lend -------------------------------------------
    // function setLend(id){

    // }
    //========================================================================================
    // ================================== Loan Request =======================================
    function loanRequest(
        uint256 original_amount,
        uint256 interest,
        uint256 payback_period
    ) external {
        address payable brrower = payable(msg.sender);

        createLoan(original_amount, interest, payback_period, brrower);
        //  emit showLoanRequests(msg.sender,loan_requests[brrower]);
    }

    function showLoanRequests(uint256 status)
        public
        returns (ShowLoan[] memory)
    {
        ShowLoan[] memory requests = new ShowLoan[](_totlaRequests);

        for (uint256 i; i < _totlaRequests; i++) {
            if (loan_requests[i].status == status) {
                LoanRequest memory request = loan_requests[i];
                requests[i].id = i;
                requests[i].original_amount = request.original_amount;
                requests[i].interest = request.interest;
                requests[i].payback_period = request.payback_period;
                requests[i].guarantor_interest = request.guarantor_interest;
                requests[i].lender_interest = request.lender_interest;
                emit showLoans(
                    i,
                    request.original_amount,
                    request.interest,
                    request.payback_period,
                    request.guarantor_interest,
                    request.lender_interest,
                    request.time_started,
                    request.status
                );
            }
        }

        return requests;
    }

    function getMyRequest(bool show) public returns (uint256) {
        for (uint256 i; i < _totlaRequests; i++) {
            if (loan_requests[i].brrower == payable(msg.sender)) {
                LoanRequest memory request = loan_requests[i];
                if (show) {
                    emit showLoans(
                        i,
                        request.original_amount,
                        request.interest,
                        request.payback_period,
                        request.guarantor_interest,
                        request.lender_interest,
                        request.time_started,
                        request.status
                    );
                }
                return i;
            }
        }
    }

    function guarateeOffer(uint256 id, uint256 g)
        public
        payable
        notBrrower(id)
    {
        require(
            msg.value == loan_requests[id].original_amount,
            "you should pay original amount of loanRequest"
        );
        require(
            loan_requests[id].guarantor_interest == 0,
            "another guarator requested"
        );
        setGuarantor(id, g, payable(msg.sender));
        emit balance(address(this).balance);
    }

    function setGuaranteeOffers(uint256 id, bool accept) public {
        require(
            loan_requests[id].brrower == msg.sender,
            "you cant accept or reject the guarantee offer"
        );
        require(loan_requests[id].status == 0, "you can't change status");
        require(
            loan_requests[id].guarantor != payable(0x00),
            "another guarator requested"
        );
        if (accept) {
            loan_requests[id].status = 1;
        } else {
            removeGuarantor(id);
            loan_requests[id].guarantor.transfer(
                loan_requests[id].original_amount
            );
        }
    }

    function lend(uint256 id) public payable notBrrower(id) {
        require(
            loan_requests[id].status == 1,
            "you can lend on rquests with status=1"
        );
        require(
            msg.value == loan_requests[id].original_amount,
            "you should pay original amount of loanRequest"
        );
        loan_requests[id].status = 2;
        loan_requests[id].lender_interest =
            loan_requests[id].interest -
            loan_requests[id].guarantor_interest;
        loan_requests[id].time_started = block.timestamp;
        loan_requests[id].brrower.transfer(loan_requests[id].original_amount);
    }

    function paybackInterest() public payable {
        uint256  loan_id = getMyRequest(false);
        require(
            msg.value == loan_requests[loan_id].interest + loan_requests[loan_id].original_amount,
            "you should pay original amount of loanRequest and it's interest"
        );
        loan_requests[loan_id].lender.transfer(loan_requests[loan_id].original_amount + loan_requests[loan_id].lender_interest);
        loan_requests[loan_id].guarantor.transfer(loan_requests[loan_id].original_amount + loan_requests[loan_id].guarantor_interest   );    
        loan_requests[loan_id].status=3;
    }

    function getInterest(uint256 id) public payable {
        require(loan_requests[id].lender==msg.sender);
        require(block.timestamp-loan_requests[id].time_started>=loan_requests[id].payback_period,"");
        loan_requests[id].lender.transfer(loan_requests[id].original_amount + loan_requests[id].lender_interest);
        loan_requests[id].status=4;
    }

    // a month is 2592000 sec
}
