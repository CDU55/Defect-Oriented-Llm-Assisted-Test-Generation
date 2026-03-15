// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract MiniBank {
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public membershipPoints;
    bool private _paused;

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    function receiveCurrency() external payable whenNotPaused {
        require(msg.value > 0, "Cannot deposit 0");
        _balances[msg.sender] += msg.value;
        membershipPoints[msg.sender]++;
    }

    function sendCurrency() external whenNotPaused {
        uint256 amountToWithdraw = _balances[msg.sender];
        require(amountToWithdraw > 0, "Insufficient balance");
        
        _executeSendCurrency(msg.sender, amountToWithdraw);
    }

    function _executeSendCurrency(address beneficiary, uint256 amount) internal {
        (bool success, ) = payable(beneficiary).call{value: amount}("");
        require(success, "Transfer failed");

        _balances[beneficiary] = 0;
        membershipPoints[beneficiary] = 0;
    }
}