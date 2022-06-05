// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts@4.4.0/token/ERC20/ERC20.sol";

contract MahdiCoin is ERC20 {
    constructor() ERC20("MahdiCoin", "MHC") {
        _mint(msg.sender, 1000 * 10**decimals());
    }
}

contract Loan is MahdiCoin {
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

    // +++++++++++++++++ universal variables ++++++++++++++++
    uint256 internal _totlaRequests;
    mapping(uint256 => LoanRequest) private loan_requests;
    enum actions {
        guarantee,
        acceptguarantee,
        lend,
        paybackloan,
        requestlend
    }
    // ++++++++++++++++++ events +++++++++++++++++++++++++++
    event showLoans(
        uint256 id,
        uint256 original_amount,
        uint256 interest,
        uint256 payback_period,
        uint256 guarantor_interest,
        uint256 lender_interest
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

    // ================================== private functions ==================================

    // function requestManage(actions action,uint256 id, )

    function getLoanRequest(uint256 id)
        private
        view
        returns (LoanRequest memory)
    {
        return loan_requests[id];
    }

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
}
