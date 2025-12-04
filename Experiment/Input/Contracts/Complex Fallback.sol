// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

contract Crowdfund {
    
    struct ContractState {
        address administrator;
        address lastInteractor;
        uint256 interactionCount;
        bool isActive;
    }

    ContractState private _state;
    
    mapping(address => uint256) public interactions;

    event FundsReceived(address indexed source, uint256 amount);
    event AdministratorWithdrawal(address indexed admin, uint256 amount);

    modifier authCheck() {
        require(_checkPrivileges(msg.sender), "Access Control: Unauthorized");
        _;
    }

    constructor() {
        _state.administrator = msg.sender;
        _state.isActive = true;
    }

    receive() external payable {
        if (_state.isActive) {
            _updateInteractionState(msg.sender);
        } else {
            revert("Contract is paused");
        }
        
        emit FundsReceived(msg.sender, msg.value);
    }

    function _checkPrivileges(address user) internal view returns (bool) {
        return user == _state.administrator;
    }

    function _updateInteractionState(address interactor) internal {
        _state.lastInteractor = interactor;
        
        _state.interactionCount++;
        interactions[interactor]++;
    }

    function withdrawFunding() external authCheck {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Transfer failed");
        
        emit AdministratorWithdrawal(msg.sender, balance);
    }

    function getLatestDonor() external view authCheck returns (address) {
        return _state.lastInteractor;
    }
    
    function toggleActive() external authCheck {
        _state.isActive = !_state.isActive;
    }
}