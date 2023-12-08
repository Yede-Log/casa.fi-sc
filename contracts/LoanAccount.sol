// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.5.0 <0.9.0;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract LoanAccount is Ownable, IERC721Receiver {

    struct MotrgagedAsset {
        address _token_contract;
        uint256 _token_id;
    }

    struct DisbursedTokenAsset {
        address _token_contract;
        uint256 _disbursed_amount;
        uint256 _principal_repaid;
    }

    address public _lender;
    address public _borrower;
    address public _asset_owner;

    uint16 public _interest_rate;
    uint256 public _payment_interval;
    uint8 public _payment_defaults;
    uint256 public _time_period;

    MotrgagedAsset _mortgaged_asset;
    DisbursedTokenAsset _disbursed_token_asset;

    constructor(
        address lender,
        address borrower, 
        address asset_owner, 
        address asset_contract, 
        uint256 asset_id, 
        address token_contract
    ) Ownable(_msgSender()) {
        _asset_owner = asset_owner;
        _mortgaged_asset = MotrgagedAsset(asset_contract, asset_id);

        _lender = lender;
        _borrower = borrower;
        _disbursed_token_asset = DisbursedTokenAsset(token_contract, 0, 0);
    }

    function disburse_loan(
        uint256 _disbursement,         
        uint256 time_period,
        uint256 payment_interval,
        uint16 interest_rate
    ) onlyOwner() external {
        IERC20 disbursed_token_asset = IERC20(_disbursed_token_asset._token_contract);
        IERC721 mortgaged_asset = IERC721(_mortgaged_asset._token_contract);

        require(time_period >= payment_interval, "Time period cannot be less than payment interval");
        require(
            disbursed_token_asset.allowance(_borrower, address(this)) >= (_disbursement * 2500) / 10000,
            "Borrower allowance too low."
        );
        require(
            disbursed_token_asset.balanceOf(_borrower) >= (_disbursement * 2500) / 10000,
            "Borrower balance too low."
        );
        require(
            disbursed_token_asset.allowance(_lender, address(this)) >= _disbursement,
            "Lender allowance too low."
        );
        require(
            disbursed_token_asset.balanceOf(_lender) >= _disbursement,
            "Lender balance too low."
        );
        require(
            mortgaged_asset.getApproved(_mortgaged_asset._token_id) == address(this),
            "Asset owner needs to approve loan account for asset id."
        );

        bool downPaymentDisbursementSuccessful;

        if (_disbursed_token_asset._disbursed_amount == 0) {
            _time_period = time_period;
            _payment_interval = payment_interval;
            _interest_rate = interest_rate;
            IERC721(_mortgaged_asset._token_contract).safeTransferFrom(_asset_owner, address(this), _mortgaged_asset._token_id);

            downPaymentDisbursementSuccessful = IERC20(_disbursed_token_asset._token_contract).transferFrom(
                _borrower,
                _asset_owner, 
                (_disbursement * 2500) / 10000
            );
        }

        bool lenderDisbursementSuccessful = IERC20(_disbursed_token_asset._token_contract).transferFrom(
            _lender, 
            _asset_owner, 
            _disbursement
        );
        _disbursed_token_asset._disbursed_amount += _disbursement;

        require(lenderDisbursementSuccessful && downPaymentDisbursementSuccessful, "Disbursement Failed. Please approve contract.");
    }

    function deduct_emi() onlyOwner() external {
        IERC20 _token = IERC20(_disbursed_token_asset._token_contract);
        uint256 _outstanding_loan_balance = _disbursed_token_asset._disbursed_amount - _disbursed_token_asset._principal_repaid;
        uint256 _payment = calculate_emi();
        if(_payment == 0) {
            IERC721(_mortgaged_asset._token_contract).safeTransferFrom(address(this), _borrower, _mortgaged_asset._token_id);
            return;
        }
        if (_token.balanceOf(_borrower) >= _payment && _token.allowance(_borrower, address(this)) >= _payment) {
            _token.transferFrom(_borrower, _lender, _payment);
            _disbursed_token_asset._principal_repaid += _payment - ((_outstanding_loan_balance * _interest_rate) / (10000 * (_time_period / _payment_interval)));
            _time_period--;
        } else {
            if (_payment_defaults < 5) {
                _payment_defaults++;
            } else {
                invalidate_contract();
            }
        }
    }

    function calculate_emi() public view returns (uint256) {
        uint256 _no_of_payments = _time_period / _payment_interval;
        uint256 _interest = (uint256(10001) + _interest_rate) ** _no_of_payments;
        uint256 _emi = ((_disbursed_token_asset._disbursed_amount - _disbursed_token_asset._principal_repaid) * (_interest / (_interest - 1)) * _interest_rate) / 10000;
        uint256 _payment = (_emi * (110 ** _payment_defaults)) / (100 ** _payment_defaults);
        return _payment;
    }

    function get_outstanding_balance() external view returns(uint256) {
        return _disbursed_token_asset._disbursed_amount - _disbursed_token_asset._principal_repaid;
    }

    function get_disbursed_asset() external view returns(DisbursedTokenAsset memory) {
        return _disbursed_token_asset;
    }

    function get_mortgaged_asset() external view returns(MotrgagedAsset memory) {
        return _mortgaged_asset;
    }

    function invalidate_contract() internal {
        IERC20 _token = IERC20(_disbursed_token_asset._token_contract);
        IERC721 _asset = IERC721(_mortgaged_asset._token_contract);

        _token.transfer(_lender, _token.balanceOf(address(this)));
        _asset.safeTransferFrom(address(this), _lender, _mortgaged_asset._token_id);
        
    }

    function prepayment(uint256 _amount) onlyOwner() external {
        IERC20 _token = IERC20(_disbursed_token_asset._token_contract);
        require(_msgSender() == _borrower, "Only borrower is allowed to do repayment.");
        require(
            (_token.allowance(_borrower, address(this)) >= _amount && _token.balanceOf(_borrower) >= _amount), 
            "Insufficient balance or allowance."
        );
        _token.transferFrom(_borrower, _lender, _amount);
        _disbursed_token_asset._principal_repaid += _amount;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
