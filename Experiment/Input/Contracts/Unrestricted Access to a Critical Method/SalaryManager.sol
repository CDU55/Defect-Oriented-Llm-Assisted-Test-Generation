// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract SalaryManager {
    struct EmployeeInfo {
        uint256 pendingSalary;
        uint256 lastWithdrawalTime;
        bool isActive;
    }

    mapping(address => EmployeeInfo) private _employees;
    address private _owner;
    uint256 private _totalAllocated;
    bool private _systemLocked;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _systemLocked = false;
    }

    function setSystemLock(bool locked) external onlyOwner {
        _systemLocked = locked;
    }

    function sendSalary(address employeeAddress) external payable onlyOwner {
        require(!_systemLocked, "System is locked");
        require(msg.value > 0, "Salary must be greater than zero");
        
        EmployeeInfo storage emp = _employees[employeeAddress];
        emp.pendingSalary += msg.value;
        emp.isActive = true;
        _totalAllocated += msg.value;
    }

    function getSalary() external {
        require(!_systemLocked, "System is locked");
        EmployeeInfo storage emp = _employees[msg.sender];
        
        require(emp.isActive, "User not active");
        require(emp.pendingSalary > 0, "No pending salary");

        uint256 amount = emp.pendingSalary;
        emp.pendingSalary = 0;
        emp.lastWithdrawalTime = block.timestamp;
        _totalAllocated -= amount;

        payable(msg.sender).transfer(amount);
    }

    function checkStatus(address user) external view returns (uint256, bool) {
        return (_employees[user].pendingSalary, _employees[user].isActive);
    }

    function cancelContract() external {
        require(_totalAllocated < address(this).balance, "Inconsistent state");
        _systemLocked = true;
        selfdestruct(payable(msg.sender));
    }
}