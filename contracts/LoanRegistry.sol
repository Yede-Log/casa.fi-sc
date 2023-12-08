// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.5.0 <0.9.0;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AutomationCompatible } from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import { LinkTokenInterface } from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

import { LoanAccount } from "./LoanAccount.sol";
import { RegistrationParams, AutomationRegistrarInterface } from "./AutomationRegistrar.sol";

contract LoanRegistry is AccessControl, AutomationCompatible {

    event CloseLoanAccount(address indexed _account);
    event LoanAccountCreated(address indexed _account);
    event LoanDisbursed(address indexed _account, uint256 _amount);
    event LoanPayment(address indexed _account, uint256 _outstanding_balance);
    event LoanPaymentReminder(address indexed _account, uint256 _amount);

    mapping(address => address) public _lenders;
    mapping(address => uint256) public _upkeep_ids;
    mapping(address => uint256) public _emi_timestamps;
    mapping(address => uint256) public _reminder_timestamps;

    address public owner;
    address public _automation_registrar_address;
    address public _link_address;

    constructor() {
        owner = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setAutomationRegistrar(address automation_registrar_address) external {
        require(_msgSender() == owner, "Only owner can perform this action.");
        _automation_registrar_address = automation_registrar_address;
    }

    function setLinkAddress(address link_address) external {
        require(_msgSender() == owner, "Only owner can perform this action.");
        _link_address = link_address;
    }

    modifier onlyLender(address _account) {
        require(_lenders[_account] == _msgSender(), "Only lender of this account can perform this action.");
        _;
    }

    function create_loan_account(
        address _borrower,
        address _asset_owner,
        address _asset_contract,
        uint256 _asset_id,
        address _token_contract
    ) external {
        LoanAccount _account = new LoanAccount(
            _msgSender(), _borrower, _asset_owner, _asset_contract,
            _asset_id, _token_contract
        );
        _lenders[address(_account)] = _msgSender();
        emit LoanAccountCreated(address(_account));
    }

    function disburse_loan(
        address _account,
        uint256 _disbursement,
        uint256 _time_period,
        uint256 _payment_interval,
        uint16 _interest_rate
    ) onlyLender(_account) external {
        LoanAccount _loan_account = LoanAccount(_account);
        _loan_account.disburse_loan(_disbursement, _time_period, _payment_interval, _interest_rate);
        _emi_timestamps[_account] = block.timestamp;
        _reminder_timestamps[_account] = block.timestamp - (_payment_interval / 2);
        registerUpkeepForLoanAccount(_loan_account);
        emit LoanDisbursed(address(this), _disbursement);
    }

    function remind_borrower(address _account) public {
        LoanAccount _loan_account = LoanAccount(_account);
        emit LoanPaymentReminder(_account, _loan_account.calculate_emi());
    }

    function deduct_emi(address _account) public {
        LoanAccount _loan_account = LoanAccount(_account);
        _loan_account.deduct_emi();
        check_loan(_loan_account);
    }

    function check_loan(LoanAccount _loan_account) internal {
        if (_loan_account.calculate_emi() <= 0) {
            AutomationRegistrarInterface(_automation_registrar_address).cancelUpkeep(_upkeep_ids[address(_loan_account)]);
            emit CloseLoanAccount(address(_loan_account));
        } else {
            emit LoanPayment(
                address(_loan_account), 
               _loan_account.get_outstanding_balance()
            );
        }
    }

    function checkUpkeep(
        bytes calldata checkdata
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        address _account_address = abi.decode(checkdata, (address));
        LoanAccount _account = LoanAccount(_account_address);
        return (
            block.timestamp - _emi_timestamps[_account_address] >= _account._payment_interval() || 
            block.timestamp - _reminder_timestamps[_account_address] >= _account._payment_interval(),
            abi.encode(_account_address)); 
    }

    function performUpkeep(bytes calldata performData) external override {
        address _account_address = abi.decode(performData, (address));
        LoanAccount _account = LoanAccount(_account_address);
        if (block.timestamp - _reminder_timestamps[_account_address] >= _account._payment_interval()) {
            remind_borrower(_account_address);
            _reminder_timestamps[_account_address] = block.timestamp;
        }
        if (block.timestamp - _emi_timestamps[_account_address] >= _account._payment_interval()) {
            deduct_emi(_account_address);
            _emi_timestamps[_account_address] = block.timestamp;
        }
    }

    function registerUpkeepForLoanAccount(LoanAccount _loan_account) internal {
        RegistrationParams memory _params = RegistrationParams(
            string(abi.encodePacked("Loan Account - ", _loan_account)),
            bytes(""),
            address(this),
            5000000,
            owner,
            0,
            abi.encode(_loan_account),
            bytes(""),
            bytes(""),
            2_000_000_000_000_000_000
        );
        LinkTokenInterface(_link_address).approve(_automation_registrar_address, _params.amount);
        uint256 upkeep_id = AutomationRegistrarInterface(_automation_registrar_address).registerUpkeep(_params);
        if (upkeep_id != 0) {
            _upkeep_ids[address(_loan_account)] = upkeep_id;
        } else {
            revert("auto-approve disabled");
        }
    }

    function withdraw(address _token, uint256 _amount) external {
        require(_msgSender() == owner, "Only owner can perform this action.");
        IERC20(_token).transfer(owner, _amount);
    }
}
