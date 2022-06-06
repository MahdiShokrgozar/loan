// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// import "@openzeppelin/contracts@4.4.0/token/ERC20/ERC20.sol";

// contract MahdiCoin is ERC20 {
//     constructor() ERC20("MahdiCoin", "MHC") {
//         _mint(msg.sender, 1000 * 10**decimals());
//     }
// }

contract Loan{
    // +++++++++++++++++++++ Structs ++++++++++++++++++
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
        uint256 time_started;
        uint256 status;
    }

    // +++++++++++++++++ universal variables ++++++++++++++++
    uint256 internal _totlaRequests;
    mapping(uint256 => LoanRequest) private loan_requests;
    enum actions {
        rejectGuarantee,
        lend,
        paybackLender,
        paybackGuarantor
    }
    // ++++++++++++++++++ events +++++++++++++++++++++++++++
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

    // ++++++++++++++++++++ contructor ++++++++++++++++++++++++
    constructor() public {
        _totlaRequests = 0;
    }

    // ++++++++++++++++++++ Modifiers ++++++++++++++++++++++++++
    modifier notBrrower(uint256 id) {
        require(
            msg.sender != loan_requests[id].brrower,
            "you can't guarantee or lend on your loan request"
        );
        _;
    }
    modifier onlyBrrower(uint256 id) {
        require(
            loan_requests[id].brrower == msg.sender,
            "you are not Brrower!"
        );
        _;
    }
    modifier onlyLender(uint256 id){
        require(loan_requests[id].lender==msg.sender);
        _;
    }
    modifier onlyStatusZero(uint256 id){
        require(loan_requests[id].status == 0, "you can't change status");
        _;
    }
    modifier onlyStatusOne(uint256 id){
        require(
            loan_requests[id].status == 1,
            "you can lend on rquests with status=1"
        );
        _;
    }
    modifier haveNotGuarantor(uint256 id){
        require(
            loan_requests[id].guarantor != payable(0x00),
            "another guarator requested"
        );
        _;
    }
    modifier justOriginalAmount(uint256 id){
        require(
            msg.value == loan_requests[id].original_amount,
            "you should pay original amount of loanRequest"
        );
        _;
    }
    modifier afterPaybackPeriod(uint256 id){
        require(block.timestamp-loan_requests[id].time_started>=loan_requests[id].payback_period,"you can request after payback period");
        _;
    }

    // ++++++++++++++++ internal functions +++++++++++++++++++++

    // function requestManage(actions action,uint256 id, )

    // ------------------- Create Loan ------------
    function createLoan(
        uint256 original_amount,
        uint256 interest,
        uint256 payback_period,
        address payable brrower
    ) internal returns (bool) {
        LoanRequest storage myLoan = loan_requests[_totlaRequests];
        myLoan.brrower = brrower;
        myLoan.original_amount = original_amount;
        myLoan.interest = interest;
        myLoan.payback_period = payback_period;
        _totlaRequests++;
        return true;
    }
    // ------------------ Get Loan Request --------------
    function getLoanRequest(uint256 id)
        internal
        view
        returns (LoanRequest memory)
    {
        return loan_requests[id];
    }
    // -------------
    function setGuarantor(
        uint256 _id,
        uint256 _g,
        address payable _guarantor
    ) internal {
        loan_requests[_id].guarantor_interest = _g;
        loan_requests[_id].guarantor = _guarantor;
    }
    // ------------
    function removeGuarantor(uint256 _id) internal {
        loan_requests[_id].guarantor_interest = 0;
        loan_requests[_id].guarantor = payable(0x00);
    }
    function setLender(uint256 _id,address payable _lender) internal{
        
        loan_requests[_id].lender_interest =
            loan_requests[_id].interest -
            loan_requests[_id].guarantor_interest;
        loan_requests[_id].time_started = block.timestamp;
        loan_requests[_id].lender=_lender;
    }
    function setStatus(uint256 _id , uint256 _status) internal{
        loan_requests[_id].status=_status;
    }
    function payAction(actions action,uint id) internal{
        if(action==actions.rejectGuarantee){
            loan_requests[id].guarantor.transfer(
                loan_requests[id].original_amount
            );
        }
        else if(action==actions.lend){
            loan_requests[id].brrower.transfer(loan_requests[id].original_amount);
        }else if(action==actions.paybackLender){
            loan_requests[id].lender.transfer(loan_requests[id].original_amount + 
                                                loan_requests[id].lender_interest);
        }else if(action==actions.paybackGuarantor){
            loan_requests[id].lender.transfer(loan_requests[id].original_amount + 
                                                loan_requests[id].guarantor_interest);
        }

    }
    // +++++++++++++++++++++++++
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

    // function paybackInterest() public payable {
    //     uint256  loan_id = getMyRequest(false);
    //     require(
    //         msg.value == loan_requests[loan_id].interest + loan_requests[loan_id].original_amount,
    //         "you should pay original amount of loanRequest and it's interest"
    //     );
    //     loan_requests[loan_id].lender.transfer(loan_requests[loan_id].original_amount + loan_requests[loan_id].lender_interest);
    //     loan_requests[loan_id].guarantor.transfer(loan_requests[loan_id].original_amount + loan_requests[loan_id].guarantor_interest   );    
    //     loan_requests[loan_id].status=3;
    // }
}


//==========================================================
contract Brrower is Loan{

    function loanRequest(
        uint256 original_amount,
        uint256 interest,
        uint256 payback_period
    ) external {
        address payable brrower = payable(msg.sender);

        createLoan(original_amount, interest, payback_period, brrower);
        //  emit showLoanRequests(msg.sender,loan_requests[brrower]);
    }

    function acceptGuaranteeOffers(uint256 id, bool accept) external 
            onlyBrrower(id) 
            onlyStatusZero(id) 
            {
        if (accept) {
            setStatus(id,1);
        } else {
            removeGuarantor(id);
            payAction(actions.rejectGuarantee,id);
        }
    }

}

contract Guarantor is Loan{
    function guarateeOffer(uint256 id, uint256 g)
        public
        payable
        notBrrower(id)
        justOriginalAmount(id)
        haveNotGuarantor(id)
    {    
        setGuarantor(id, g, payable(msg.sender));
    }
}


contract lender is Loan{

    function lend(uint256 id) public payable notBrrower(id) onlyStatusOne(id) justOriginalAmount(id){
        setLender(id,payable(msg.sender));
        payAction(actions.lend,id);
        setStatus(id,2);
    }

    function getInterest(uint256 id) public payable onlyLender(id) afterPaybackPeriod(id){
        payAction(actions.paybackLender,id);
        setStatus(id,4);
    }

}

